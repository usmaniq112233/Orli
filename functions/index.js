const functions = require("firebase-functions");
const { defineSecret } = require("firebase-functions/params");
const SENDGRID_API_KEY = defineSecret("SENDGRID_API_KEY");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
//const sgMail = require("@sendgrid/mail");
const {getMessaging} = require("firebase-admin/messaging");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {log, warn, error} = require("firebase-functions/logger");

initializeApp();
//sgMail.setApiKey(functions.config().sendgrid.key);


exports.checkAndDeliverMessages = onSchedule(
    {
      schedule: "every 1 minutes",
      region: "us-central1",
    secrets: [SENDGRID_API_KEY],
    },
    async (event) => {
      const db = getFirestore();
      const now = new Date();
        // Initialize SendGrid only when the function actually runs
        const sgMail = require("@sendgrid/mail");
           sgMail.setApiKey(SENDGRID_API_KEY.value()); // ✅ Use the secret value

      const snapshot = await db
          .collectionGroup("scheduledMessages")
          .where("deliveryDate", "<=", now)
          .where("status", "==", "scheduled")
          .get();

      if (snapshot.empty) {
        console.log("📭 No pending messages to send.");
        return;
      }

      console.log(`📨 Found ${snapshot.size} messages to send`);

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const ref = doc.ref;
        const userId = ref.path.split("/")[1];

        const userDoc = await db.collection("users").doc(userId).get();

        const recipientEmail = data.recipientEmail;
        const senderName = userDoc.exists ?
            userDoc.data().fullName :
            "A loved one";
        const subject = data.subject || "You've received a message";
        const contentText = data.contentText || "";

        const mediaURL = data.mediaFilePath;
        const mediaLinkHTML = mediaURL ?
            `<p>You can view the attached media here:<br/>
                 <a href="${mediaURL}" target="_blank">${mediaURL}</a></p>` :
            "";

        const emailHTML = `
            <p>Dear ${data.recipient || "friend"},</p>
            <p>${senderName} left you a message scheduled for today.</p>
            <p><strong>Subject:</strong> ${subject}</p>
            <p>${contentText}</p>
            ${mediaLinkHTML}
            <p>With care,<br/>The Orli App</p>
          `;

        if (recipientEmail) {
          try {
            await sgMail.send({
              to: recipientEmail,
              from: {
                email: "orlisupport@proton.me",
                name: "Orli App",
              },
              subject: `🎁 You've received a message from ${senderName}`,
              html: emailHTML,
            });

            console.log(`✅ Email sent to ${recipientEmail}`);
          } catch (err) {
            console.error(`❌ Failed to send email to ${recipientEmail}:`, err);
          }
        }

        try {
          await ref.update({status: "sent"});
          console.log(`📝 Updated message ${doc.id} to 'sent'`);
        } catch (err) {
          console.error(`❌ Failed to update status for ${doc.id}`, err);
        }
      }
    },
);


//exports.sendPushNotification = onDocumentUpdated(
//    "users/{userId}/scheduledMessages/{messageId}",
//    async (event) => {
//      const userId = event.params.userId;
//      const messageId = event.params.messageId;
//
//      log(`📨 Triggered for user ${userId}, message ${messageId}`);
//
//      const newData = event.data.after.data();
//      if (!newData || !newData.deliveryDate) {
//        warn("No deliveryDate found. Skipping.");
//        return;
//      }
//
//      const now = new Date();
//      const scheduledTime = newData.deliveryDate.toDate();
//
//      if (scheduledTime > now) {
//        log("📅 Message scheduled for future. No action taken.");
//        return;
//      }
//
//      const db = getFirestore();
//      const userDoc = await db.collection("users").doc(userId).get();
//
//      if (!userDoc.exists) {
//        warn(`User doc not found for ${userId}`);
//        return;
//      }
//
//      const fcmToken = userDoc.data().fcmToken;
//
//      // --- Send Push Notification ---
//      if (fcmToken) {
//        const pushMessage = {
//          token: fcmToken,
//          notification: {
//            title: "📤 Message Delivered",
//            body: `Message to ${newData.recipient || "recipient"} was sent.`,
//          },
//        };
//
//        try {
//          const response = await getMessaging().send(pushMessage);
//          log(`✅ Notification sent: ${response}`);
//        } catch (err) {
//          error("❌ Error sending push notification", err);
//        }
//      }
//    },
//);

