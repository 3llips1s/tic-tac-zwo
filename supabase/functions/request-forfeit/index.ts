import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

// CORS headers to allow requests
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle preflight requests for CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get the gameSessionId from the request body
    const { gameSessionId } = await req.json();
    if (!gameSessionId) {
      throw new Error('Game session ID is required.');
    }

    // Create a Supabase admin client to interact with the database
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    // Get the user's JWT from the request headers to identify them
    const userAuthHeader = req.headers.get('Authorization');
    if (!userAuthHeader) {
      throw new Error('User not authenticated.');
    }
    const { data: { user } } = await supabaseAdmin.auth.getUser(userAuthHeader.replace('Bearer ', ''));
    if (!user) {
      throw new Error('Authentication failed.');
    }

    // --- Core Logic ---
    // 1. Fetch the current game session
    const { data: game, error: gameError } = await supabaseAdmin
      .from('game_sessions')
      .select('player1_id, player2_id, status')
      .eq('id', gameSessionId)
      .single();

    if (gameError || !game) {
      throw new Error('Game session not found.');
    }

    // 2. Validate the game state
    if (game.status !== 'in_progress') {
      return new Response(JSON.stringify({ message: 'Game is already over.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    // 3. Determine the player who is NOT the one making the request
    const winnerId = game.player1_id === user.id ? game.player2_id : game.player1_id;

    // 4. Update the game session to reflect the forfeit
    const { error: updateError } = await supabaseAdmin
      .from('game_sessions')
      .update({
        status: 'forfeited',
        winner_id: winnerId,
        is_game_over: true,
        player1_ready: false,
        player2_ready: false,
      })
      .eq('id', gameSessionId);

    if (updateError) {
      throw updateError;
    }

    // --- Success ---
    return new Response(JSON.stringify({ message: 'Game forfeited successfully.' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    // --- Error Handling ---
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});