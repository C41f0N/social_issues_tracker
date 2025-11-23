serve(async (req)=>{
  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
    const auth = req.headers.get("Authorization");
    if (!auth) return new Response("Unauthorized", {
      status: 401
    });
    const user = (await supabase.auth.getUser(auth.replace("Bearer ", ""))).data.user;
    const { issue_id } = await req.json();
    await supabase.from("issue_upvote").delete().eq("issue_id", issue_id).eq("user_id", user.id);
    return new Response(JSON.stringify({
      success: true
    }), {
      status: 200
    });
  } catch (e) {
    return new Response(JSON.stringify({
      error: e.message
    }), {
      status: 400
    });
  }
});
