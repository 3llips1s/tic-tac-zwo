import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders});
  }

  try {
    // isConnecting = true for a join event
    // = false for a leave event
    const { gameSessionId, isConnecting } = await req.json();
    if (!gameSessionId) {
      throw new Error('Game session ID is required.');
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const userAuthHeader = req.headers.get('Authorization');
    if (!userAuthHeader) {
      throw new Error('User not authenticated.');
    }
    const { data: { user } } = await supabaseAdmin.auth.getUser(userAuthHeader.replace('Bearer ', ''));
    if (!user) {
      throw new Error('Authentication failed.');
    }

    // core logic
    const { data: game, error: gameError } = await supabaseAdmin
      .from('game_sessions')
      .select('player1_id, player2_id, status')
      .eq('id', gameSessionId)
      .single();

    if (gameError || !game) {
      throw new Error('Game session not found.');
    }
    if (game.status !== 'in_progress') {
      return new Response(JSON.stringify({ message: 'Game is already over.' }), { status: 400 });
    }

    // identify the other player 
    const otherPlayerId = game.player1_id === user.id ? game.player2_id : game.player1_id;

    let updatePayload;
    if (isConnecting) {
      // clear disconnection fields if player is reconnecting
      updatePayload = {
        disconnected_player_id: null,
        player_disconnected_at: null,
      };
    } else {
      updatePayload = {
        disconnected_player_id: otherPlayerId,
        player_disconnected_at: new Date().toISOString(),
      };
    }

    const { error: updateError } = await supabaseAdmin
      .from('game_sessions')
      .update(updatePayload)
      .eq('id', gameSessionId);

      if (updateError) {
        throw updateError;
      }

      return new Response(JSON.stringify({ message: 'Disconnection status update.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
