import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

interface SendPushNotificationRequest {
  userId: string;
  title: string;
  body: string;
  type: string;
  refId?: string;
}

interface SendPushNotificationResponse {
  success: boolean;
  message: string;
  notificationId?: string;
  fcmSent?: boolean;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Parse request body
    const requestData: SendPushNotificationRequest = await req.json();
    const { userId, title, body, type, refId } = requestData;

    // Validate required fields
    if (!userId || !title || !body || !type) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Missing required fields: userId, title, body, type",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate notification type
    const validTypes = ["comment", "message", "topic_vote", "suggestion_vote", "milestone", "system"];
    if (!validTypes.includes(type)) {
      return new Response(
        JSON.stringify({
          success: false,
          message: `Invalid notification type. Must be one of: ${validTypes.join(", ")}`,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Initialize Supabase client with service role key
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Supabase configuration missing",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // 1. Get user's FCM token from profiles table
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("fcm_token")
      .eq("id", userId)
      .single();

    if (profileError) {
      console.error("[SEND-PUSH-NOTIFICATION] Error fetching profile:", profileError);
      return new Response(
        JSON.stringify({
          success: false,
          message: `Error fetching user profile: ${profileError.message}`,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const fcmToken = profile?.fcm_token;
    let fcmSent = false;

    // 2. Insert notification into database
    const { data: notification, error: notificationError } = await supabase
      .from("notifications")
      .insert({
        user_id: userId,
        type: type,
        title: title,
        body: body,
        ref_id: refId,
        is_read: false,
      })
      .select()
      .single();

    if (notificationError) {
      console.error("[SEND-PUSH-NOTIFICATION] Error inserting notification:", notificationError);
      return new Response(
        JSON.stringify({
          success: false,
          message: `Error creating notification: ${notificationError.message}`,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const notificationId = notification?.id;

    // 3. Send push notification if FCM token exists
    if (fcmToken) {
      try {
        const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");
        if (!fcmServerKey) {
          console.warn("[SEND-PUSH-NOTIFICATION] FCM_SERVER_KEY not set, skipping push notification");
        } else {
          const fcmResponse = await sendFCMNotification(
            fcmToken,
            title,
            body,
            type,
            refId,
            fcmServerKey
          );

          if (fcmResponse.success) {
            fcmSent = true;
            console.log(`[SEND-PUSH-NOTIFICATION] FCM notification sent successfully to user ${userId}`);
          } else {
            console.error(`[SEND-PUSH-NOTIFICATION] FCM send failed: ${fcmResponse.error}`);
          }
        }
      } catch (fcmError) {
        console.error("[SEND-PUSH-NOTIFICATION] FCM error:", fcmError);
        // Don't fail the whole request if FCM fails
      }
    } else {
      console.log(`[SEND-PUSH-NOTIFICATION] No FCM token for user ${userId}, skipping push notification`);
    }

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        message: "Notification processed successfully",
        notificationId,
        fcmSent,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[SEND-PUSH-NOTIFICATION] Unhandled error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        message: `Internal server error: ${error.message}`,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

// Helper function to get OAuth2 access token for Firebase Admin SDK
async function getAccessToken(serviceAccount: any): Promise<string | null> {
  try {
    const tokenUrl = "https://oauth2.googleapis.com/token";
    
    const jwtHeader = {
      alg: "RS256",
      typ: "JWT",
    };

    const now = Math.floor(Date.now() / 1000);
    const jwtPayload = {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: tokenUrl,
      exp: now + 3600,
      iat: now,
    };

    // In a real implementation, you would sign the JWT with the private key
    // For Deno edge functions, we'll use a simpler approach with service account
    const response = await fetch(tokenUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: createJWT(serviceAccount, jwtHeader, jwtPayload),
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("[SEND-PUSH-NOTIFICATION] OAuth2 token error:", errorText);
      return null;
    }

    const tokenData = await response.json();
    return tokenData.access_token;
  } catch (error) {
    console.error("[SEND-PUSH-NOTIFICATION] Error getting access token:", error);
    return null;
  }
}

// Simplified JWT creation (in production, use a proper JWT library)
function createJWT(serviceAccount: any, header: any, payload: any): string {
  // This is a simplified version - in production, use a proper JWT library
  // For now, we'll return a placeholder
  console.warn("[SEND-PUSH-NOTIFICATION] Using simplified JWT creation - implement proper JWT signing in production");
  return "simplified-jwt-placeholder";
}

async function sendFCMNotification(
  token: string,
  title: string,
  body: string,
  type: string,
  refId?: string,
  serverKey?: string
): Promise<{ success: boolean; error?: string }> {
  try {
    // Get service account from environment
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      // Fall back to legacy API if service account not configured
      return await sendFCMNotificationLegacy(token, title, body, type, refId, serverKey);
    }

    const serviceAccount = JSON.parse(serviceAccountJson);
    const projectId = serviceAccount.project_id;
    
    // Get OAuth2 access token
    const accessToken = await getAccessToken(serviceAccount);
    
    if (!accessToken) {
      return { success: false, error: "Failed to get OAuth2 access token" };
    }

    // Use FCM HTTP v1 API
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    const message = {
      message: {
        token: token,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: type,
          ref_id: refId || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "HIGH",
          notification: {
            channel_id: "suggesta_notifications",
            sound: "default",
            icon: "ic_notification",
            color: "#FF6B35",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              sound: "default",
              badge: 1,
            },
          },
        },
      },
    };

    const response = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[SEND-PUSH-NOTIFICATION] FCM v1 API error: ${response.status} - ${errorText}`);
      return {
        success: false,
        error: `FCM v1 API error: ${response.status}`,
      };
    }

    const result = await response.json();
    console.log(`[SEND-PUSH-NOTIFICATION] FCM v1 response:`, result);

    // Check for errors in response
    if (result.error) {
      return {
        success: false,
        error: result.error.message || "FCM v1 API error",
      };
    }

    return { success: true };
  } catch (error) {
    console.error("[SEND-PUSH-NOTIFICATION] FCM v1 error:", error);
    return {
      success: false,
      error: error.message || "Unknown FCM v1 error",
    };
  }
}

// Legacy FCM API (fallback)
async function sendFCMNotificationLegacy(
  token: string,
  title: string,
  body: string,
  type: string,
  refId?: string,
  serverKey?: string
): Promise<{ success: boolean; error?: string }> {
  if (!serverKey) {
    return { success: false, error: "FCM server key not configured" };
  }

  try {
    const fcmUrl = "https://fcm.googleapis.com/fcm/send";

    const payload = {
      to: token,
      notification: {
        title,
        body,
        sound: "default",
        badge: "1",
      },
      data: {
        type,
        ref_id: refId || "",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        channel_id: "suggesta_notifications",
      },
      android: {
        priority: "high",
        notification: {
          channel_id: "suggesta_notifications",
          sound: "default",
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

    const response = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        "Authorization": `key=${serverKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[SEND-PUSH-NOTIFICATION] FCM legacy API error: ${response.status} - ${errorText}`);
      return {
        success: false,
        error: `FCM legacy API error: ${response.status}`,
      };
    }

    const result = await response.json();
    console.log(`[SEND-PUSH-NOTIFICATION] FCM legacy response:`, result);

    if (result.failure === 1) {
      return {
        success: false,
        error: result.results?.[0]?.error || "Unknown FCM error",
      };
    }

    return { success: true };
  } catch (error) {
    console.error("[SEND-PUSH-NOTIFICATION] FCM legacy error:", error);
    return {
      success: false,
      error: error.message || "Unknown FCM legacy error",
    };
  }
}