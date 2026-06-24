
function create_line()
	local line = Drawing.new("Line")
	line.Visible = false
	return line
end

function create_text()
	local text = Drawing.new("Text")
	text.Visible = false
	text.Center = true
	text.Outline = true
	text.Font = 2
	return text
end

function create_square()
	local square = Drawing.new("Square")
	square.Visible = false
	square.Filled = false
	return square
end