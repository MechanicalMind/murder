local taunts = {}

function addTaunt(cat, soundFile, sex)
	if !taunts[cat] then
		taunts[cat] = {}
	end
	if !taunts[cat][sex] then
		taunts[cat][sex] = {}
	end
	local t = {}
	t.sound = soundFile
	t.sex = sex
	t.category = cat
	table.insert(taunts[cat][sex], t)
end

// male
addTaunt("help", "vo/npc/male01/help01.wav", "male")

addTaunt("scream", "vo/npc/male01/runforyourlife01.wav", "male")
addTaunt("scream", "vo/npc/male01/runforyourlife02.wav", "male")
addTaunt("scream", "vo/npc/male01/runforyourlife03.wav", "male")
addTaunt("scream", "vo/npc/male01/watchout.wav", "male")
addTaunt("scream", "vo/npc/male01/gethellout.wav", "male")

addTaunt("morose", "vo/npc/female01/question31.wav", "male")
addTaunt("morose", "vo/npc/male01/question30.wav", "male")
addTaunt("morose", "vo/npc/male01/question20.wav", "male")
addTaunt("morose", "vo/npc/male01/question25.wav", "male")
addTaunt("morose", "vo/npc/male01/question15.wav", "male")

addTaunt("funny", "vo/npc/male01/doingsomething.wav", "male")
addTaunt("funny", "vo/npc/male01/busy02.wav", "male")
addTaunt("funny", "vo/npc/male01/gordead_ques07.wav", "male")
addTaunt("funny", "vo/npc/male01/notthemanithought01.wav", "male")
addTaunt("funny", "vo/npc/male01/notthemanithought02.wav", "male")
addTaunt("funny", "vo/npc/male01/question06.wav", "male")
addTaunt("funny", "vo/npc/male01/question09.wav", "male")

// female
addTaunt("help", "vo/npc/female01/help01.wav", "female")

addTaunt("scream", "vo/npc/female01/runforyourlife01.wav", "female")
addTaunt("scream", "vo/npc/female01/runforyourlife02.wav", "female")
addTaunt("scream", "vo/npc/female01/watchout.wav", "female")
addTaunt("scream", "vo/npc/female01/gethellout.wav", "female")

addTaunt("morose", "vo/npc/female01/question30.wav", "female")
addTaunt("morose", "vo/npc/female01/question25.wav", "female")
addTaunt("morose", "vo/npc/female01/question20.wav", "female")
addTaunt("morose", "vo/npc/female01/question15.wav", "female")

addTaunt("funny", "vo/npc/female01/doingsomething.wav", "female")
addTaunt("funny", "vo/npc/female01/busy02.wav", "female")
addTaunt("funny", "vo/npc/female01/gordead_ques07.wav", "female")
addTaunt("funny", "vo/npc/female01/notthemanithought01.wav", "female")
addTaunt("funny", "vo/npc/female01/notthemanithought02.wav", "female")
addTaunt("funny", "vo/npc/female01/question06.wav", "female")
addTaunt("funny", "vo/npc/female01/question09.wav", "female")

concommand.Add("mu_taunt", function (ply, com, args, full)
	if ply.LastTaunt && ply.LastTaunt > CurTime() then return end
	if !ply:Alive() then return end
	if ply:Team() != 2 then return end

	if #args < 1 then return end
	local cat = args[1]:lower()
	if !taunts[cat] then return end

	local sex = string.lower(ply.ModelSex or "male")
	if !taunts[cat][sex] then return end

	local taunt = table.Random(taunts[cat][sex])
	ply:EmitSound(taunt.sound)

	ply.LastTaunt = CurTime() + SoundDuration(taunt.sound) + 0.3
end)