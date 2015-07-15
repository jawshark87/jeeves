# Description:
#   Tells the user general info about the Smartsheet data that jeeves is
#   interacting with.
#
# Dependencies: none.
#
# Configuration:
#   HUBOT_SMARTSHEET_API_KEY
#   HUBOT_SMARTSHEET_DEFAULT_SHEET_ID
#
# Commands:
#   ss default - Tells the user the current default sheet.
#
# Notes:
#   When interacting with Smartsheet, there will be a default sheet that jeeves
#   will search if no additional sheet is specified. This default sheet should
#   contain all of our client info from CenterIC.

module.exports = (robot) ->
  robot.hear /ss default/i, (res) ->
    url = "https://api.smartsheet.com/2.0/sheets/#{process.env.HUBOT_SMARTSHEET_DEFAULT_SHEET_ID}"
    robot.http(url)
      # Smartsheet API requires that the header contain 'Authorization: "Bearer
      # <API key>"'. 'Content-Type' is something I saw on StackOverflow and
      # the hubot docs as something I should put in there. Not sure if the
      # command is '.header' or '.headers'.
      .headers(Authorization: "Bearer #{process.env.HUBOT_SMARTSHEET_API_KEY}", Accept: 'application/json')
      # The GET request. err = possible error, res = response specified in
      # ss-default's constructor, body = the info from Smartsheet in JSON format.
      .get() (err, res, body) ->
        # 'data' contains the info from Smartsheet in JSON format.
        data = JSON.parse body
        if res.statusCode isnt 200
          res.send "Request didn't come back HTTP 200 :("
          return
        else
          # Tell the user the name of the current default sheet.
          res.send "The current default sheet is #{data.name}."
