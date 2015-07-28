# Description:
#   Tells the user info about our clients. Info taken from a specified
#   Smartsheet document.
#
# Dependencies: none.
#
# Configuration:
#   HUBOT_SMARTSHEET_API_KEY
#   HUBOT_SMARTSHEET_DEFAULT_SHEET_ID
#
# Commands:
#   ss clients <sheet ID> - Lists names of all clients from the specified sheet. To list the entire client database, type 'default' instead of a sheet ID.
#
# Notes:
#	  A column in the specified sheet *must* have the title 'Client Name', or this won't
#	  work.
#
#   ss clients - not functional
#
#	  Currently, this only searches the default document. In the future, maybe it
#	  could search a user-specified document.

module.exports = (robot) ->
  robot.hear /ss clients (.*)/i, (msg) ->
    sheetID = msg.match[1]
    url = ""
    auth = "Bearer #{process.env.HUBOT_SMARTSHEET_API_KEY}"
    colNum = -1
    rowNums = []
    clientNames = []
    if sheetID is "default"
      url = "https://api.smartsheet.com/2.0/sheets/#{process.env.HUBOT_SMARTSHEET_DEFAULT_SHEET_ID}"
    else
      url = "https://api.smartsheet.com/2.0/sheets/#{sheetID}"
    # Populate 'rows' with all row values from the default sheet and set
    # columnId to colNum.
    robot.http(url)
      .headers(Authorization: auth, Accept: 'application/json')
      .get() (err, res, body) ->
        data = JSON.parse(body)
        msg.send "The current default sheet is #{data.name}."
        if res.statusCode isnt 200
          msg.send "An error occurred when processing your request:
                    #{res.statusCode}. The list of error codes can be found at
                    http://bit.ly/ss-errors. Talk to the nearest code nerd for
                    assistance."
        else
          # Populate 'rows' with all rowId's from default sheet.
          rowNums = (row.id for row in data.rows)
          # Parses 'columns' for column titled 'Name'. Stops when it finds it.
          for column in data.columns
            if column.title.toLowerCase() == "client name"
              colNum = column.id
              break
            else
              return undefined
    # If colNum = -1, tell user the column wasn't found and must be titled
    # 'Name' (no quotes).
    if colNum == -1
      msg.send "Sorry, I couldn't find the 'client name' column. A reminder: the column containing client names *must* be titled 'Client Name' (no quotes) in order for me to read it."
      return
    # Get value of cell given a rowId and columnId.
    getName = (rowNum, colNum) ->
      robot.http(url + "/rows/" + rowNum + "/columns/" + colNum)
        .headers(Authorization: auth, Accept: 'application/json')
        .get() (err, res, body) ->
          data = JSON.parse(body)
          # Parses array of all cells in column. If the name in the cell isn't
          # in the last position of the array 'clientNames', it adds it to
          # 'message'.
          if res.statusCode isnt 200
            msg.send "An error occurred when processing your request:
                      #{res.statusCode}. The list of error codes can be found at
                      http://bit.ly/ss-errors. Talk to the nearest code nerd for
                      assistance."
          else
            return data.value
    # Populate clientNames with the names of our clients (once for each client)
    # using getName.
    for row, i in rowNums
      if clientNames[i] == getName(row, colNum)
        clientNames.push getName(row, colNum) + "\n"
    # clientNames = (getName(rowId, colNum) + "\n" for rowId in rows)
    msg.send clientNames
