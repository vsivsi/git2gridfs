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
  console.log "Args parsed"
  unless target.verifyRepo()
    console.error 'Not a valid git repo!'
    exit 1
  console.log "About to detect packs"
  if target.detectPacks()
    console.log "Packs detected"
    target.unpackRepo()

target.parseArgs = (args = []) ->
  argv = yargs.parse args
  console.dir argv
  if argv.h
    yargs.showHelp()
    exit 1

target.verifyRepo = (args) ->
  target.parseArgs args
  ls('.git').indexOf('objects') isnt -1

target.detectPacks = (args) ->
  target.parseArgs args
  console.log "Detecting packs"
  res = ls('.git/objects/pack/pack-*.pack').length > 0
  console.log "Res: #{res}"
  res

target.unpackRepo = (args) ->
  target.parseArgs args
  console.log "Unpacking!"
  # create a temp dir
  tmpdir = Math.floor(1000000000000*Math.random()).toString(36)
  mkdir tmpdir
  mv '.git/objects/pack/*', "#{tmpdir}/"
  for pack in ls "#{tmpdir}/pack-*.pack"
    exec "git unpack-objects < #{pack}"
  rm '-rf', tmpdir

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
