############################################################################
#     Copyright (C) 2015 by Vaughn Iverson
#     git2gridfs is free software released under the MIT/X11 license.
#     See included LICENSE file for details.
############################################################################

require 'shelljs/make'
yargs = require 'yargs'
async = require 'async'

argv = {}

target.all = (args) ->
  target.parseArgs args
  target.verifyRepo()
  target.unpackRepo()

target.parseArgs = (args = []) ->
  argv = yargs.parse args
  console.dir argv
  if argv.h
    yargs.showHelp()
    exit 1

target.verifyRepo = (args) ->
  target.parseArgs args

target.unpackRepo = (args) ->
  target.parseArgs args



yargs.usage('''

Usage: $0 [target] [-- [] [] [] ...]

Output:

''')
  .example('', '''

Something...
''')
    .default('host', '127.0.0.1')
    .describe('host', 'The domain name or IP address of the host to connect with')
    .default('port', 3000)
    .describe('port', 'The server port number to connect with')
    .default('env', 'METEOR_TOKEN')
    .describe('env', 'The environment variable to check for a valid token')
    .default('method', 'account')
    .describe('method', 'The login method: currently "email", "username", "account" or "token"')
    .default('retry', 5)
    .describe('retry', 'Number of times to retry login before giving up')
    .describe('ssl', 'Use an SSL encrypted connection to connect with the host')
    .boolean('ssl')
    .default('ssl', false)
    .describe('plaintext', 'For Meteor servers older than v0.8.2, fallback to sending the password as plaintext')
    .default('plaintext', false)
    .boolean('plaintext')
    .boolean('h')
    .alias('h','help')
    .wrap(null)
    .version((() -> require('../package').version))

# module?.exports = login
