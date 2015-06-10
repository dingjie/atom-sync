path = require 'path'

DEBUG = 1

module.exports = ->
    if DEBUG
        stackPattern = ///
            at (.*) \((.*)\)
        ///

        caller = new Error().stack.split("\n")[2]
        if m = caller.match stackPattern
            console.info m[2].split(':')[0].split('/').slice(-1) + ':' + m[1].split('.').slice(-1)[0].trim() + ':' + m[2].split(':')[1]

        switch arguments.length
            when 0 then return
            when 1 then console.debug arguments[0]
            else console.debug arguments
