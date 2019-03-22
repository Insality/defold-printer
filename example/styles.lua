return {
	default = {
		font_height = 42,
		spacing = 1, -- pixels between letters
		scale = 1, -- scale of character
		waving = false, -- if true - do waving by sinus
		color = "#f5e3bc",
		speed = 0.04,
		appear = 0.05,
		shaking = 0, -- shaking power. Set to 0 to disable
		sound = "letter",
		can_skip = true,
		shake_on_write = 0 -- when letter appear, shake dialogue screen
	},

	hard = {
		color = "#f22222",
		speed = 0.1,
		appear = 0,
		shake_on_write = 4
	},

	slow_appear = {
		speed = 0.08,
		appear = 0.15,
		color = "#FFFFFF"
	},

	define_style = {
		speed = 0.1,
		shake_on_write = 3,
		color = "#DA4576"
	},
}
