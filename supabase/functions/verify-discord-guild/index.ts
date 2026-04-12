import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const DISCORD_TARGET_GUILD_ID = Deno.env.get("DISCORD_TARGET_GUILD_ID");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // 必須環境変数が未設定の場合はサイレント全拒否を防ぐため明示的にエラーを返す
  if (!DISCORD_TARGET_GUILD_ID) {
    return new Response(
      JSON.stringify({ error: "サーバー設定エラー: DISCORD_TARGET_GUILD_ID が未設定です" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "認証ヘッダーがありません" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { provider_token } = await req.json();
    if (!provider_token) {
      return new Response(
        JSON.stringify({ error: "provider_token が必要です" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // limit=200 は Discord API の上限値。
    // 200件を超えるサーバーに参加しているユーザーはページネーションが必要だが、
    // 一般ユーザーでは該当しないため現状は上限値取得で対応する。
    const guildsRes = await fetch("https://discord.com/api/v10/users/@me/guilds?limit=200", {
      headers: { Authorization: `Bearer ${provider_token}` },
    });

    if (!guildsRes.ok) {
      return new Response(
        JSON.stringify({ error: "Discord API エラー", details: await guildsRes.text() }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const guilds = await guildsRes.json();
    const isMember = guilds.some((g: { id: string }) => g.id === DISCORD_TARGET_GUILD_ID);

    if (!isMember) {
      return new Response(
        JSON.stringify({ error: "指定された Discord サーバーに参加していません", verified: false }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ verified: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "内部エラー", details: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
