-------------------------------------------------
-- Force one city-state ally/friend refresh right after a game load.
--
-- CSUA state is deliberately not serialized: CvPlayer::doTurn() rebuilds it from scratch every turn
-- through RefreshCSAlliesFriends(). On a load that leaves the first turn running on the values the
-- previous turn wrote, so refresh once as soon as the load screen closes.
-------------------------------------------------

Events.LoadScreenClose.Add(function()
	for i = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
		local pPlayer = Players[i];
		if pPlayer ~= nil and pPlayer:IsAlive() and not pPlayer:IsMinorCiv() and not pPlayer:IsBarbarian() then
			if pPlayer.RefreshCSAlliesFriends ~= nil then
				pPlayer:RefreshCSAlliesFriends();
			end
		end
	end
end);
