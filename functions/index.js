/**
 * gp2 — Firebase Cloud Functions
 *
 * SETUP INSTRUCTIONS
 * ──────────────────
 * 1. In your project root run:
 *      firebase init functions
 *    Choose JavaScript, say NO to ESLint, say YES to installing dependencies.
 *
 * 2. Replace the generated functions/index.js with this file.
 *
 * 3. Make sure firebase-admin and firebase-functions are in functions/package.json
 *    (they are installed by default when you run `firebase init functions`).
 *
 * 4. Deploy with:
 *      firebase deploy --only functions
 *
 * WHAT THIS DOES
 * ──────────────
 * sendMessageNotification
 *   Triggers whenever a new message document is created inside
 *   chats/{chatId}/messages/{messageId}.
 *
 *   Steps:
 *   1. Read the new message: senderId, message text / type.
 *   2. Find the recipient (the other user in chats/{chatId}.users[]).
 *   3. Read the recipient's FCM token from users/{recipientId}.fcmToken.
 *      (The token is saved by login.dart after every successful login.)
 *   4. Send an FCM notification via admin.messaging().send().
 *   5. If the token is stale/invalid, clear it from Firestore so we
 *      don't keep trying to send to a dead token.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

exports.sendMessageNotification = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const { chatId } = context.params;
    const msgData = snap.data();

    if (!msgData) {
      console.log("No message data — skipping.");
      return null;
    }

    const senderId = msgData.senderId;
    const msgType = msgData.type || "text";
    const msgText =
      msgType === "image" ? "📷 Sent a photo" : (msgData.message || "");

    // ── 1. Get the chat document to find the recipient ──────────────────
    let chatSnap;
    try {
      chatSnap = await db.collection("chats").doc(chatId).get();
    } catch (err) {
      console.error("Failed to read chat doc:", err);
      return null;
    }

    if (!chatSnap.exists) {
      console.log("Chat doc not found:", chatId);
      return null;
    }

    const chatData = chatSnap.data();
    const users = chatData.users || [];

    // The recipient is the user in the chat who is NOT the sender
    const recipientId = users.find((uid) => uid !== senderId);
    if (!recipientId) {
      console.log("Could not determine recipient for chat:", chatId);
      return null;
    }

    // ── 2. Get the sender's display name ───────────────────────────────
    let senderName = "Someone";
    try {
      const senderSnap = await db.collection("users").doc(senderId).get();
      if (senderSnap.exists) {
        const sd = senderSnap.data();
        const full = `${sd.firstName || ""} ${sd.lastName || ""}`.trim();
        if (full) senderName = full;
      }
    } catch (_) {
      // Non-fatal — we still send the notification with the fallback name
    }

    // ── 3. Get the recipient's FCM token ───────────────────────────────
    let recipientSnap;
    try {
      recipientSnap = await db.collection("users").doc(recipientId).get();
    } catch (err) {
      console.error("Failed to read recipient doc:", err);
      return null;
    }

    if (!recipientSnap.exists) {
      console.log("Recipient user doc not found:", recipientId);
      return null;
    }

    const recipientData = recipientSnap.data();
    const fcmToken = recipientData.fcmToken;

    if (!fcmToken || fcmToken.trim() === "") {
      console.log("Recipient has no FCM token — skipping notification.");
      return null;
    }

    // ── 4. Build and send the FCM message ──────────────────────────────
    const message = {
      token: fcmToken,
      notification: {
        title: senderName,
        body: msgText,
      },
      data: {
        // Pass chatId and otherUserId so the app can open the right screen
        // when the notification is tapped (handle in main.dart with
        // FirebaseMessaging.onMessageOpenedApp).
        chatId: chatId,
        senderId: senderId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "chat_messages", // define this channel in your Android app
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log("Notification sent successfully:", response);
    } catch (err) {
      // If the token is invalid / unregistered, clear it from Firestore
      if (
        err.code === "messaging/invalid-registration-token" ||
        err.code === "messaging/registration-token-not-registered"
      ) {
        console.warn(
          "Stale FCM token for user",
          recipientId,
          "— removing it."
        );
        await db.collection("users").doc(recipientId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      } else {
        console.error("Error sending notification:", err);
      }
    }

    return null;
  });
