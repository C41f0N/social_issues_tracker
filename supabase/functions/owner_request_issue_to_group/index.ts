serve(async (req)=>{
  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
    const auth = req.headers.get("Authorization");
    if (!auth) return new Response("Unauthorized", {
      status: 401
    });
    const owner = (await supabase.auth.getUser(auth.replace("Bearer ", ""))).data.user;
    const { group_id, issue_id, target_user_id } = await req.json();
    await supabase.from("group_join_request").insert({
      group_id,
      issue_id,
      requester_id: owner.id,
      target_user_id,
      type: "owner_request",
      status: "pending"
    });
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
