GM.Name 	= "Murder"
GM.Author 	= "MechanicalMind"
// credits to Minty Fresh for some styling on the scoreboard
// credits to Waddlesworth for the logo and menu icon
GM.Email 	= ""
GM.Website 	= "www.codingconcoctions.com/murder/"

team.SetUp(1, "Spectators", Color(150, 150, 150))
team.SetUp(2, "Players", Color(26, 120, 245))

GM.ShowAdminsOnScoreboard = CreateConVar("mu_scoreboard_show_admins", 1, bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED), "Should show admins on scoreboard" )
GM.AdminPanelAllowed = CreateConVar("mu_allow_admin_panel", 1, bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED), "Should allow admins to use mu_admin_panel" )
