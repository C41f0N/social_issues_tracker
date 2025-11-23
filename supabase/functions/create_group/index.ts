serve(async (req)=>{
  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
    const auth = req.headers.get("Authorization");
    if (!auth) return new Response("Unauthorized", {
      status: 401
    });
    const user = (await supabase.auth.getUser(auth.replace("Bearer ", ""))).data.user;
    const { name, description } = await req.json();
    const { data, error } = await supabase.from("group").insert({
      name,
      description,
      owner_id: user.id
    }).select().single();
    if (error) throw error;
    return new Response(JSON.stringify(data), {
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
