extends Node

var num_players = 8
var available = []  # The available players.
var queue = []  # The queue of sounds to play.
var introPlaying = false
var outroPlaying = false

signal intro_finished


enum SOUNDS {
	SMOKE,
	SHOT,
	BOUNCE,
	TANK_MOVE,
	MINE,
	BLAST,
	TANK_DEATH,
	BULLET_SHOT,
	MINE_CANT,
	TANK_KILL
}

enum TRACKS {
	WIN,
	LOSE,
	INTRO,
	MAIN,
	REPLAY,
}

func _ready():
	# Create the pool of AudioStreamPlayer nodes.
	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.connect("finished", self, "_on_stream_finished", [p])
		p.bus = "master"

func _on_stream_finished(stream):
	# When finished playing a stream, make the player available again.
	available.append(stream)

func play(sound):
	queue.append(sound)

func startBGMusic(track):
	match(track):
		TRACKS.INTRO:
			$BGMusic.stream = preload("res://SFX/intro.wav")
			$BGMusic.volume_db = -5
			$BGMusic.play()
			introPlaying = true
		TRACKS.MAIN:
			$BGMusic.stream = preload("res://SFX/main.wav")
			$BGMusic.volume_db = -5
			$BGMusic.play()
		TRACKS.WIN:
			if ($BGMusic.stream != preload("res://SFX/lose.wav")):
				$BGMusic.stream = preload("res://SFX/win.wav")
				$BGMusic.volume_db = -5
				$BGMusic.play()
				outroPlaying = true
		TRACKS.LOSE:
			if ($BGMusic.stream != preload("res://SFX/win.wav")):
				$BGMusic.stream = preload("res://SFX/lose.wav")
				$BGMusic.volume_db = -5
				$BGMusic.play()
				outroPlaying = true
		TRACKS.REPLAY:
			$BGMusic.stream = preload("res://SFX/replay.wav")
			$BGMusic.volume_db = -5
			$BGMusic.play()
			introPlaying = true

func _process(_delta):
	# Play a queued sound if any players are available.
	if not queue.empty() and not available.empty():
		var sound = queue.pop_front()
		var player = available.pop_front()
		
		match(sound):
			SOUNDS.SMOKE:
				player.stream = preload("res://SFX/smoke.wav")
				player.volume_db = -15
			SOUNDS.SHOT:
				player.stream = preload("res://SFX/shot.wav")
				player.volume_db = -10
			SOUNDS.BOUNCE:
				player.stream = preload("res://SFX/bounce.wav")
				player.volume_db = -2
			SOUNDS.TANK_MOVE:
				player.stream = preload("res://SFX/tank_move.wav")
				player.volume_db = -10
			SOUNDS.MINE:
				player.stream = preload("res://SFX/mine.wav")
				player.volume_db = -10
			SOUNDS.BLAST:
				player.stream = preload("res://SFX/bomb.wav")
				player.stream.loop_mode = 0
				player.volume_db = -15
			SOUNDS.TANK_DEATH:
				player.stream = preload("res://SFX/tank_death.wav")
				player.stream.loop_mode = 0
				player.volume_db = -15
			SOUNDS.BULLET_SHOT:
				player.stream = preload("res://SFX/bullet_shot.wav")
				player.stream.loop_mode = 0
				player.volume_db = -15
			SOUNDS.MINE_CANT:
				player.stream = preload("res://SFX/mine_cant.wav")
				player.stream.loop_mode = 0
				player.volume_db = -5
			SOUNDS.TANK_KILL:
				player.stream = preload("res://SFX/tank_kill.wav")
				player.stream.loop_mode = 0
				player.volume_db = -6
		
		player.play()

func _on_BGMusic_finished():
	print("BGMusic terminada. introPlaying =", introPlaying)
	if introPlaying:
		introPlaying = false
		emit_signal("intro_finished")
		startBGMusic(TRACKS.MAIN)
	elif outroPlaying:
		outroPlaying = false
	else:
		# Si no es intro ni outro, reiniciar música normal
		startBGMusic(TRACKS.MAIN)

func pauseBGMusic():
	if $BGMusic.playing:
		$BGMusic.stream_paused = true

