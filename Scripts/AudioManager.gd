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
			
func startMusicaFondo(track):
	match(track):
		TRACKS.INTRO:
			$MusicaFondo.stream = preload("res://SFX/intro.wav")
			$MusicaFondo.volume_db = -5
			$MusicaFondo.play()
			introPlaying = true
		TRACKS.MAIN:
			$MusicaFondo.stream = preload("res://SFX/main.wav")
			$MusicaFondo.volume_db = -5
			$MusicaFondo.play()
		TRACKS.WIN:
			if ($MusicaFondo.stream != preload("res://SFX/lose.wav")): # We don't want this to play when we already lost and the lose sfx is playing
				$MusicaFondo.stream = preload("res://SFX/win.wav")
				$MusicaFondo.volume_db = -5
				$MusicaFondo.play()
				outroPlaying = true
		TRACKS.LOSE:
			if ($MusicaFondo.stream != preload("res://SFX/win.wav")): # We don't want this to play when we already won and the win sfx is playing
				$MusicaFondo.stream = preload("res://SFX/lose.wav")
				$MusicaFondo.volume_db = -5
				$MusicaFondo.play()
				outroPlaying = true
		TRACKS.REPLAY:
			$MusicaFondo.stream = preload("res://SFX/replay.wav")
			$MusicaFondo.volume_db = -5
			$MusicaFondo.play()
			introPlaying = true

func _process(_delta):
	# Play a queued sound if any players are available.
	if not queue.empty() and not available.empty():
		var sound = queue.pop_front()
		match(sound):
			SOUNDS.SMOKE:
				available[0].stream = preload("res://SFX/smoke.wav")
				available[0].volume_db = -15
			SOUNDS.SHOT:
				available[0].stream = preload("res://SFX/shot.wav")
				available[0].volume_db = -10
			SOUNDS.BOUNCE:
				available[0].stream = preload("res://SFX/bounce.wav")
				available[0].volume_db = -2
			SOUNDS.TANK_MOVE:
				available[0].stream = preload("res://SFX/tank_move.wav")
				available[0].volume_db = -10
			SOUNDS.MINE:
				available[0].stream = preload("res://SFX/mine.wav")
				available[0].volume_db = -10
			SOUNDS.BLAST:
				available[0].stream = preload("res://SFX/bomb.wav")
				available[0].stream.loop_mode = 0
				available[0].volume_db = -15
			SOUNDS.TANK_DEATH:
				available[0].stream = preload("res://SFX/tank_death.wav")
				available[0].stream.loop_mode = 0
				available[0].volume_db = -15
			SOUNDS.BULLET_SHOT:
				available[0].stream = preload("res://SFX/bullet_shot.wav")
				available[0].stream.loop_mode = 0
				available[0].volume_db = -15
			SOUNDS.MINE_CANT:
				available[0].stream = preload("res://SFX/mine_cant.wav")
				available[0].stream.loop_mode = 0
				available[0].volume_db = -5
			SOUNDS.TANK_KILL:
				available[0].stream = preload("res://SFX/tank_kill.wav")
				available[0].stream.loop_mode = 0
				available[0].volume_db = -6
		available[0].play()
		available.pop_front()

func _on_MusicaFondo_finished():
	if (introPlaying):
		emit_signal("intro_finished")
		introPlaying = false
		startMusicaFondo(TRACKS.MAIN)
	else:
		if (outroPlaying):
			outroPlaying = false
		else:
			startMusicaFondo(TRACKS.INTRO)


