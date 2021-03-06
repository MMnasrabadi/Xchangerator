const path = require('path');
const { get } = require('lodash');
const fbCollectionConst = require('./constants/fbCollection');
const fbFieldConst = require('./constants/fbField');
const requestUrlConst = require('./constants/requestUrl');
const relationConst = require('./constants/relation');
const debug = require('debug')('appserver:firestore');
const customLogger = require('./logger');
const logger = customLogger('appserver:firestore');
const {
  getRawLatestCache,
  existsRawLatestCache,
  setexHydratedLatest,
} = require('./cacheUtil');
const { getHydratedLatest } = require('./dataFetch');
const request = require('superagent');
const createError = require('http-errors');

const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: 'https://xchangerator.firebaseio.com',
});

const db = admin.firestore();

const getAllDocsFactory = collectionPath => {
  return async db => {
    let docQuery = db.collection(collectionPath);
    try {
      let docQuerySnapshot = await docQuery.get();
      return docQuerySnapshot;
    } catch (e) {
      throw e;
    }
  };
};

const getUsers = getAllDocsFactory(fbCollectionConst.users);

/**
 * Get the specified subcollection querySnapshot of a document
 * @param db Firestore instance
 * @param docSnapshotPath
 * @param subCollectionName
 * @returns {Promise<QuerySnapshot<T>>} subColQuerySnapshot
 */
const getSubcollection = async ({ db, docSnapshotPath, subCollectionName }) => {
  let subColQuery = db.collection(
    path.join(docSnapshotPath, subCollectionName),
  );
  const subColQuerySnapshot = await subColQuery.get();
  return subColQuerySnapshot;
};

const computeRate = async (from, to) => {
  try {
    let cacheExists = await existsRawLatestCache();
    if (!cacheExists) {
      // fetch latest rates and write to redis
      const hydratedLatestRates = await getHydratedLatest();
      await setexHydratedLatest(hydratedLatestRates);
    }
    const dataString = await getRawLatestCache();
    const { rates } = JSON.parse(dataString);
    const toRate = rates[to];
    const fromRate = rates[from];
    if (toRate && fromRate) {
      return toRate / fromRate;
    }
    return void 0;
  } catch (e) {
    logger.error(e.stack);
  }
};

const isTriggeredNotification = async ({
  from,
  to,
  relation,
  target,
  disabled,
}) => {
  const currentRate = await computeRate(from, to);
  if (currentRate) {
    if (!disabled) {
      debug(`currentRate ${currentRate} ${from}-${to}-${relation} ${target} `);
      switch (relation) {
        case 'GT':
          return target < currentRate;
        case 'LT':
          return target > currentRate;
      }
    }
  }
  return false;
};

/**
 *
 * @param db Firestore instance
 * @param getUsers Function to fetch the 'users' collection snapshot
 * @returns {Promise<[]>} A Promise resolved to an array of objects
 * {
 *    deviceTokens: String[],
 *    from: String,
 *    to: String,
 *    relation: String,
 *    target: Number,
 * }
 */
const getTriggeredData = async (db, getUsers) => {
  try {
    const triggeredDataArr = [];
    let usersDocSnapshot = await getUsers(db);
    for (let userDocSnapshot of usersDocSnapshot.docs) {
      const deviceTokens = get(
        userDocSnapshot.data(),
        fbFieldConst.deviceTokens,
      );

      if (deviceTokens) {
        const notificationsSnapshot = await getSubcollection({
          db,
          docSnapshotPath: userDocSnapshot.ref.path,
          subCollectionName: fbCollectionConst.notifications,
        });

        const notificationDocs = notificationsSnapshot.docs;
        for (let ntQueryDocSnapshot of notificationDocs) {
          const { target, condition, disabled } = ntQueryDocSnapshot.data();
          const conditionArr = condition.split('-');
          const [from, to, relation] = conditionArr;
          if (
            await isTriggeredNotification({
              from,
              to,
              relation,
              target,
              disabled,
            })
          ) {
            const ntRef = ntQueryDocSnapshot.ref; // notificationDocRef
            triggeredDataArr.push({
              deviceTokens,
              from,
              to,
              relation,
              target,
              ntRef,
            });
          }
        }
      } else {
        logger.error(
          `${userDocSnapshot.ref.path} ${fbFieldConst.deviceTokens} is undefined`,
        );
      }
    }
    return triggeredDataArr;
  } catch (e) {
    logger.error(e.stack);
  }
};

const sendNotifications = async () => {
  const triggeredDataArr = await getTriggeredData(db, getUsers);
  debug(triggeredDataArr);

  let successCount = 0;
  let failureCount = 0;

  const finalPromiseArr = triggeredDataArr.map(async data => {
    const { deviceTokens, from, to, relation, target, ntRef } = data;
    // for each notification, send it to all devices registered by the user
    const reqPromiseArr = deviceTokens.map(async deviceToken => {
      const result = await request
        .post(requestUrlConst.FCM)
        .set('Authorization', process.env.FCM_SERVER_KEY)
        .send({
          to: deviceToken,
          notification: {
            body: `${from} to ${to} is now ${relationConst[relation]} ${target}`,
            title: `Xchangerator Alert`,
            content_available: true,
            priority: 'high',
            sound: 'default',
          },
        })
        .retry(3, (err, res) => {
          if (err) {
            logger.error(
              `[sendNotifications] retry error:
                  ${err}
                  ${JSON.stringify(res)}`,
            );
          }
        });
      if (result.body.success) {
        successCount += 1;
        await ntRef.update({ disabled: true });
      }
      if (result.body.failure) {
        failureCount += 1;
        const errorMessage = `[sendNotifications] sending error:
            deviceToken: ${deviceToken}
            ${JSON.stringify(result.body.results)}
            ${result.body.failure} messages failed to send.`;
        logger.error(errorMessage);
        throw Error(errorMessage);
      }
      return result;
    });
    return Promise.allSettled(reqPromiseArr);
  });
  await Promise.allSettled(finalPromiseArr);
  logger.info(
    `[sendNotifications] ${successCount} notifications sent, ${failureCount} notifications failed`,
  );
};

module.exports = { db, getUsers, getTriggeredData, sendNotifications };
