const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const nodemailer = require("nodemailer");

// Secrets stockés via Secret Manager (jamais en clair dans le code)
const gmailUser = defineSecret("GMAIL_USER");
const gmailPass = defineSecret("GMAIL_APP_PASSWORD");

exports.sendContactEmail = onDocumentCreated(
    {
        document: "messages/{messageId}",
        secrets: [gmailUser, gmailPass],
    },
    async (event) => {
        const data = event.data.data();

        const transporter = nodemailer.createTransport({
            service: "gmail",
            auth: {
                user: gmailUser.value(),
                pass: gmailPass.value(), // mot de passe d'application Gmail, pas le mot de passe principal
            },
        });

        try {
            await transporter.sendMail({
                from: `"AzizArt — Site web" <${gmailUser.value()}>`,
                to: gmailUser.value(), // ton email de réception
                replyTo: data.email,
                subject: `[Contact AzizArt] ${data.subject || "Nouveau message"}`,
                text: `Nom: ${data.name}\nEmail: ${data.email}\nTéléphone: ${data.phone || "—"}\n\n${data.message}`,
            });

            await event.data.ref.update({ status: "sent" });
        } catch (error) {
            console.error("Erreur envoi email:", error);
            await event.data.ref.update({ status: "failed", errorMessage: String(error) });
        }
    },
);