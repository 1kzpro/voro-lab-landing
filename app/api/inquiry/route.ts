import { NextRequest, NextResponse } from "next/server";

interface FormData {
  name: string;
  businessName: string;
  phoneNumber: string;
  businessAddress?: string;
  instagram?: string;
  message: string;
}

export async function POST(request: NextRequest) {
  try {
    const formData: FormData = await request.json();

    // Validate required fields
    if (
      !formData.name ||
      !formData.businessName ||
      !formData.phoneNumber ||
      !formData.message
    ) {
      return NextResponse.json(
        { error: "Missing required fields" },
        { status: 400 }
      );
    }

    // Format the message for Telegram
    const telegramMessage = `
🆕 *New Inquiry from Voro Lab Website*

👤 *Name:* ${formData.name}
🏢 *Business:* ${formData.businessName}
📞 *Phone:* ${formData.phoneNumber}
${formData.businessAddress ? `📍 *Address:* ${formData.businessAddress}` : ""}
${formData.instagram ? `📱 *Instagram:* ${formData.instagram}` : ""}

💬 *Message:*
${formData.message}

---
*Sent at:* ${new Date().toLocaleString("en-US", {
      timeZone: "America/Los_Angeles",
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    })} PST
    `.trim();

    // Send to Telegram
    const telegramBotToken = process.env.TELEGRAM_BOT_TOKEN;
    const telegramChatId = process.env.TELEGRAM_CHAT_ID;

    if (!telegramBotToken) {
      console.error("TELEGRAM_BOT_TOKEN not found in environment variables");
      return NextResponse.json(
        { error: "Telegram bot not configured" },
        { status: 500 }
      );
    }

    if (!telegramChatId) {
      console.error("TELEGRAM_CHAT_ID not found in environment variables");
      return NextResponse.json(
        { error: "Telegram chat ID not configured" },
        { status: 500 }
      );
    }

    const telegramResponse = await fetch(
      `https://api.telegram.org/bot${telegramBotToken}/sendMessage`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          chat_id: telegramChatId,
          text: telegramMessage,
          parse_mode: "Markdown",
        }),
      }
    );

    if (!telegramResponse.ok) {
      const errorData = await telegramResponse.json();
      console.error("Telegram API error:", errorData);
      return NextResponse.json(
        { error: "Failed to send notification" },
        { status: 500 }
      );
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Error processing inquiry:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
