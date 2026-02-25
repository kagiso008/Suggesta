import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

interface DeleteAccountRequest {
  userId: string;
}

interface DeleteAccountResponse {
  success: boolean;
  message: string;
  deletedAt?: string;
}

// JWT validation function
async function validateJWTAndUserId(authHeader: string, requestedUserId: string): Promise<{ isValid: boolean; error?: string }> {
  try {
    // Extract token from "Bearer <token>" format
    const token = authHeader.replace("Bearer ", "");
    
    // Create a client to verify the JWT
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") || "";
    
    if (!supabaseUrl || !supabaseAnonKey) {
      return { isValid: false, error: "Server configuration error" };
    }
    
    const client = createClient(supabaseUrl, supabaseAnonKey);
    
    // Verify the JWT token
    const { data: { user }, error } = await client.auth.getUser(token);
    
    if (error) {
      console.error("[DELETE-ACCOUNT] JWT validation error:", error.message);
      return { isValid: false, error: "Invalid or expired authentication token" };
    }
    
    if (!user) {
      return { isValid: false, error: "User not found in token" };
    }
    
    // Verify the user in the token matches the requested user ID
    if (user.id !== requestedUserId) {
      console.error(`[DELETE-ACCOUNT] User ID mismatch: Token user=${user.id}, Requested user=${requestedUserId}`);
      return { isValid: false, error: "You can only delete your own account" };
    }
    
    return { isValid: true };
  } catch (error) {
    console.error("[DELETE-ACCOUNT] JWT validation exception:", error);
    return { isValid: false, error: "Authentication validation failed" };
  }
}

serve(async (req: Request) => {
  console.log("[DELETE-ACCOUNT] ========== REQUEST RECEIVED ==========");
  console.log("[DELETE-ACCOUNT] Method:", req.method);
  console.log("[DELETE-ACCOUNT] Headers:", Object.fromEntries(req.headers));
  
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, content-type",
        "Access-Control-Max-Age": "86400",
      },
    });
  }
  
  // Only allow POST requests
  if (req.method !== "POST") {
    console.error("[DELETE-ACCOUNT] ❌ Invalid method:", req.method);
    return new Response(
      JSON.stringify({ success: false, message: "Method not allowed" }),
      {
        status: 405,
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }

  try {
    // Get the request body
    const requestBody = await req.json();
    const { userId } = requestBody as DeleteAccountRequest;
    
    console.log("[DELETE-ACCOUNT] Request body:", requestBody);
    console.log("[DELETE-ACCOUNT] User ID from request:", userId);

    // Validate request
    if (!userId) {
      console.error("[DELETE-ACCOUNT] ❌ Missing user ID in request");
      const errorResponse = {
        success: false,
        message: "User ID is required",
      };
      console.log("[DELETE-ACCOUNT] Returning error response:", errorResponse);
      return new Response(
        JSON.stringify(errorResponse),
        {
          status: 400,
          headers: { 
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    // Get authorization header
    const authHeader = req.headers.get("authorization");
    console.log("[DELETE-ACCOUNT] Authorization header:", authHeader ? "Present" : "Missing");
    
    if (!authHeader) {
      console.error("[DELETE-ACCOUNT] ❌ Missing authorization header");
      return new Response(
        JSON.stringify({
          success: false,
          message: "Authorization header is required",
        }),
        {
          status: 401,
          headers: { 
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    // Validate JWT token and ensure user can only delete their own account
    console.log("[DELETE-ACCOUNT] Validating JWT token...");
    const validationResult = await validateJWTAndUserId(authHeader, userId);
    
    if (!validationResult.isValid) {
      console.error("[DELETE-ACCOUNT] ❌ JWT validation failed:", validationResult.error);
      return new Response(
        JSON.stringify({
          success: false,
          message: validationResult.error || "Authentication failed",
        }),
        {
          status: 401,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }
    console.log("[DELETE-ACCOUNT] ✅ JWT validation passed");

    // Create Supabase admin client (with service role key)
    console.log("[DELETE-ACCOUNT] Creating Supabase admin client...");
    
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
    
    console.log("[DELETE-ACCOUNT] SUPABASE_URL present:", !!supabaseUrl);
    console.log("[DELETE-ACCOUNT] SUPABASE_SERVICE_ROLE_KEY present:", !!supabaseServiceRoleKey);
    
    if (!supabaseUrl || !supabaseServiceRoleKey) {
      console.error("[DELETE-ACCOUNT] ❌ Missing Supabase environment variables");
      return new Response(
        JSON.stringify({
          success: false,
          message: "Server configuration error",
        }),
        {
          status: 500,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }
    
    const adminClient = createClient(
      supabaseUrl,
      supabaseServiceRoleKey
    );
    console.log("[DELETE-ACCOUNT] ✅ Admin client created");

    // Step 1: Delete user's avatar files from storage (if avatars bucket exists)
    console.log("[DELETE-ACCOUNT] Attempting to delete user's avatar files...");
    try {
      const { data: files, error: listError } = await adminClient.storage
        .from("avatars")
        .list();

      if (listError) {
        console.warn("[DELETE-ACCOUNT] Could not list avatar files (bucket may not exist or no permissions):", listError.message);
        console.warn("[DELETE-ACCOUNT] This is not critical - continuing with account deletion...");
      } else if (files && files.length > 0) {
        // Filter files that belong to the user
        // Look for files that start with the user's ID or contain the user's ID
        const userFiles = files.filter(file =>
          file.name.startsWith(`${userId}_`) ||
          file.name.includes(userId) ||
          file.name.match(new RegExp(`^${userId}[^a-zA-Z0-9]`))
        );
        
        console.log(`[DELETE-ACCOUNT] Found ${userFiles.length} avatar files to delete out of ${files.length} total files`);
        
        if (userFiles.length > 0) {
          // Delete each file
          let deletedCount = 0;
          let failedCount = 0;
          
          for (const file of userFiles) {
            const { error: deleteFileError } = await adminClient.storage
              .from("avatars")
              .remove([file.name]);
            
            if (deleteFileError) {
              console.warn(`[DELETE-ACCOUNT] Failed to delete avatar file ${file.name}:`, deleteFileError.message);
              failedCount++;
            } else {
              console.log(`[DELETE-ACCOUNT] ✅ Deleted avatar file: ${file.name}`);
              deletedCount++;
            }
          }
          
          console.log(`[DELETE-ACCOUNT] Avatar cleanup summary: ${deletedCount} deleted, ${failedCount} failed`);
        } else {
          console.log("[DELETE-ACCOUNT] No avatar files found for this user");
        }
      } else {
        console.log("[DELETE-ACCOUNT] No files in avatars bucket");
      }
    } catch (storageError) {
      console.warn("[DELETE-ACCOUNT] Error during avatar cleanup:", storageError);
      console.warn("[DELETE-ACCOUNT] Continuing with account deletion despite avatar cleanup error");
      // Continue with account deletion even if avatar cleanup fails
    }

    // Step 2: Delete the user from auth.users (this will cascade delete related data)
    console.log("[DELETE-ACCOUNT] Attempting to delete user from auth.users...");
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      userId
    );

    if (deleteError) {
      console.error("[DELETE-ACCOUNT] ❌ Error deleting user from auth:", deleteError);
      return new Response(
        JSON.stringify({
          success: false,
          message: `Failed to delete account: ${deleteError.message}`,
        }),
        {
          status: 500,
          headers: { 
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    // Success response
    console.log("[DELETE-ACCOUNT] ✅ User successfully deleted!");
    const response: DeleteAccountResponse = {
      success: true,
      message: "Account and all associated data (including avatar) have been successfully deleted",
      deletedAt: new Date().toISOString(),
    };

    console.log("[DELETE-ACCOUNT] Returning success response:", response);
    console.log("[DELETE-ACCOUNT] ========== REQUEST COMPLETED SUCCESSFULLY ==========");
    
    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    console.error("[DELETE-ACCOUNT] ❌ Unexpected error:", error);
    console.error("[DELETE-ACCOUNT] Error type:", error instanceof Error ? error.constructor.name : typeof error);
    console.error("[DELETE-ACCOUNT] Error message:", error instanceof Error ? error.message : String(error));
    console.error("[DELETE-ACCOUNT] Error stack:", error instanceof Error ? error.stack : "No stack trace");
    
    return new Response(
      JSON.stringify({
        success: false,
        message: `An unexpected error occurred: ${error instanceof Error ? error.message : "Unknown error"}`,
      }),
      {
        status: 500,
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});
