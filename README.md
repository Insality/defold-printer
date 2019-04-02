![](docs/logo.jpg)

# Printer
A symbol-by-symbol text writer for Defold Engine. Developed for rich game dialogs.
Support UTF-8 symbols (via utf-8.lua). So Russian and other 2+ bytes symbol languages are supported.

# Install

Add library to dependency:
`https://github.com/Insality/defold-printer/archive/master.zip`

# Basic Setup

Place printer template on you gui scene. Setup font of text and set size of printer background.

Text will appearing from top-left of this background. You can setup alpha of this node to see text area.

setup in gui module:
```lua
local printer = require "printer.printer"
function init(self)
	self.printer = printer.new(self, template_name)
end
function update(self, dt)
	printer.update(self)
end
function final(self)
	printer.final(self)
end
```

And usage will be like this:

```lua
self.printer:print("This is just simple text")
```

# Styles
Style is lua table with parameters. Default style look like:
```lua
default = {
	font_height = 28,
	spacing = 1,
	scale = 1,
	waving = false,
	color = "#FFFFFF",
	speed = 0.05,
	appear = 0.01,
	shaking = 0,
	sound = false,
	can_skip = true,
	shake_on_write = 0,
}
```
## Parameters:
- `font_height` in pixels, height of every symbol or image
- `spacing` in pixels, distance between symbols
- `scale` set scale of every symbol to this value
- `waving` set true, to enable waving symbol effect
- `color` string in hex, like "#CACACA". Set color of every text symbol
- `speed` in seconds. The speed of text typing
- `appear` in seconds. The speed of symbol appearing. Via gui.animate from alpha 0 -> 1
- `shaking` in pixels. Set value > 0 to enable shaking of every symbol
- `sound` string. Name of sound, what will be played, when text is start appearing. Need to rewrite printer.play_sound function.
- `can_skip` if false, printer.instant_appear will not work, while text with this style is appearing
- `shake_on_write` when true, shake all text symbols when any symbol is start appearing

## Style usage
To setup your styles, use `printer.add_styles( {styles} )`. Styles is array of lua-table with style parameters.

By default, all new print text have *default* style. To change it, you need point needed style like this:
`{my_style}This is styled text`

You can reset style to default by using `{/}`. Example:
`{my_style}This is styled text. {/}But this no`

You can use `{n}` to make new line. Example:
`This row on first line.{n}This line on second line`

You can mix many styles in one row. Example:
`{Illidan_name}Illidan{/}: you are {red}not {waving}prepared{/}!`

# Advanced Setup

## Dialog skip and next
To handle next behavior, like to appear all text if it printing, or go to next text if it already showed, you can use something like this on touch event:
```lua
if self.printer.is_print then
	self.printer:instant_appear()
else
	self.index = self.index + 1
	if self.index <= #self.texts then
		self.printer:print(self.texts[self.index])
	end
end
```


## Source predefined styles
You can predefine styles for special sources. It will become default style for current text. For example, if your setup source style:
`printer.add_source_style("bob", "bob_style")`
add call next:
`printer:print("Any text you want", "bob")`
Instead of *default* style, it will be printed with style *bob_style*

## Word styles
You can predefine styles for special word. For example, if you setup word style:
`printer.add_word_style("powerful", "cool_style")`
and will print next text: `The Defold is amazing, powerful engine`
It will auto apply style and will looks similar to:
`The Defold is amazing, {cool_style}powerful{/} engine`
*Point*: the word is case sensitive. You can use it for coloring characters name in your game. The word style will extend default style of current text.
*Point*: It will work with source predefined styles. Just extend default style of source predefined text.

## Image usage
You can insert images in your text via `{image:name}` syntax.
It will place image node and call `gui.play_flipbook(node, name)` to this
Example:
`printer:print("Lets trade this for 500 {image:coins}!)`

## Multiply instancing
You can create multiply printer instances with printer.new, using different templates

## Usage examples
```lua
self.printer:print("This is {red}test with red style")
self.printer:print("This is {amazing}multi-{blue}styled text")
self.printer:print("This is text with{n}new line. And image here {image:coins}")
self.printer:print("This is {red}red text and {/}return to default")
self.printer:print("This is with source to use another default style", "Illidan")
```

# API

## printer.new(self, prefab_name)
Create new printer instance to use it for print text
### PARAMETERS
- `self` gui self context
- `prefab_name` printer template name of gui scene

## printer.print(instance, text, [source]
Start printing text on selected instance
### PARAMETERS
- `instance` printer instance, created by *printer.new*
- `text` string, text to start printing
- `source` string, name of source to setup other default style for this text

## printer.is_print
Boolean value to check, if printer now printing text or not

## printer.instant_appear(instance)
Instantly appear all nodes, what currently printing. If text is already printed, have no effect
### PARAMETERS
- `instance` printer instance, created by *printer.new*

## printer.clear(instance)
Clear all current printed text
### PARAMETERS
- `instance` printer instance, created by *printer.new*

## printer.play_sound(name)
To play sound, you should override this function.
### PARAMETERS
- `name` string, name of played sound

## printer.add_styles(styles)
Add custom styles to printer module
### PARAMETERS
- `styles` lua table with style parameters. Elements are: *{style_id: {params}}*

## printer.add_source_style(source, style)
Add one custom source style to printer module
### PARAMETERS
- `source` string, source id to use it as source param in *printer.print* function
- `style` string, style id

## printer.add_word_style(word, style)
Add one custom word style to printer module
### PARAMETERS
- `word` string, word what will be wrapped with pointed style
- `style` string, style id

## printer.update(self, dt)
Place it in gui update function to update all print instance you have.
### PARAMETERS
- `self` gui self context
- `dt` dt parameter from update script

## printer.final(self)
Place it in gui final function to correct final printer component
### PARAMETERS
- `self` gui self context

# Author
Insality

# License
My code is under MIT license

[utf8 module](https://github.com/tst2005/lua-utf8string) MIT
