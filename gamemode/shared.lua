GM.Name 	= "Murder"
GM.Author 	= "MechanicalMind"
// credits to Minty Fresh for some styling on the scoreboard
// credits to Waddlesworth for the logo and menu icon
GM.Email 	= ""
GM.Website 	= "www.codingconcoctions.com/murder/"
GM.Version = "25"

function GM:SetupTeams()
	team.SetUp(1, translate.teamSpectators, Color(150, 150, 150))
	team.SetUp(2, translate.teamPlayers, Color(26, 120, 245))
end
GM:SetupTeams()
