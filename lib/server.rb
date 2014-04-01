#!/usr/local/bin/ruby
require 'webrick'
include WEBrick

dir = Dir::pwd
port = 3000

server = HTTPServer.new(
  :Port            => port,
  :DocumentRoot    => dir
)

class RockPaperScissors < WEBrick::HTTPServlet::AbstractServlet
  def do_GET request, response
    response.status = 200
    response['Content-Type'] = 'text/html'
    current_lines = File.readlines("./rockpaperscissors.html")

    line_array = []
    current_lines.each do |line|
      if line.include?("RPS-status")
        line_array << "<div id=\"status\">Rock... Paper... Scissors...</div>\n"
      else
        unless line.include?("New Game")
          line_array << line
        end
      end
    end

    response.body = line_array.join("\n")
  end

  def do_POST request, response
    human_move = human_throw(request.query['sign'])
    computer_move = computer_throw
    game_status_short = check_moves(human_move, computer_move)
    game_status = stringify_game_status(game_status_short)

    response.status = 200
    response['Content-Type'] = 'text/html'
    current_lines = File.readlines("./rockpaperscissors.html")

    line_array = []
    current_lines.each_with_index do |line, index|
      if line.include?("RPS-status")
        line_array << "<div id=\"status\">\n"
        line_array << "  <p>The suspense! It's killing me!</p>\n"
        line_array << "  <p>You threw: <span class=\"sign\">#{request.query['sign']}</span></p>\n"
        line_array << "  <p>The computer threw: <span class=\"sign\">#{move_as_string(computer_move)}</span></p>\n"
        line_array << "  <p id=\"outcome\" class=\"#{game_status_short}\">#{game_status}</p>\n"
        line_array << "</div>\n"
      elsif index < 8 || index > 16
        line_array << line
      end
    end

    response.body = line_array.join("\n")
  end

  def stringify_game_status gs
    case gs
      when "win"
        "You WIN!"
      when "lose"
        "You LOSE!"
      when "tie"
        "It's a tie!"
    end
  end

  def human_throw move_string
    case move_string
    when "Rock"
      0
    when "Paper"
      1
    when "Scissors"
      2
    end
  end

  def computer_throw
    return rand(3)
  end

  def move_as_string move
    case move
      when 0
        "Rock"
      when 1
        "Paper"
      when 2
        "Scissors"
    end
  end

  def check_moves human_move, computer_move
    case human_move <=> computer_move
    when 0
      "tie"
    else
      human_move == (computer_move + 1) % 3 ? "win" : "lose"
    end
  end
end

class Styling < WEBrick::HTTPServlet::AbstractServlet
  def do_GET request, response
    response.status = 200
    response['Content-Type'] = 'text/css'
    response.body = File.readlines('./rps.css').join("\n")
  end
end

server.mount '/', RockPaperScissors
server.mount '/throw', RockPaperScissors
server.mount '/rps.css', Styling

trap("INT"){ server.shutdown }
server.start