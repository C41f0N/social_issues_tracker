serve(async (req)=>{
  const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
  const auth = req.headers.get("Authorization");
  if (!auth) return new Response("Unauthorized", {
    status: 401
  });
  const user = (await supabase.auth.getUser(auth.replace("Bearer ", ""))).data.user;
  const { group_id, weight } = await req.json();
  await supabase.from("group_upvote").insert({
    group_id,
    weight,
    user_id: user.id
  });
  return new Response(JSON.stringify({
    success: true
  }), {
    status: 200
  });
});
