############################################################################
#     Copyright (C) 2015 by Vaughn Iverson
#     git2gridfs is free software released under the MIT/X11 license.
#     See included LICENSE file for details.
############################################################################

require 'shelljs/global'
yargs = require 'yargs'
async = require 'async'
mongo = require 'mongodb'
gfs = require 'gridfs-locking-stream'
fs = require 'fs'

argv = {}
git = ''
db = null

yargs.usage('''

Usage: $0 [options]

''')
  .example('', '''

Something...
''')
    .default('host', 'localhost')
    .describe('host', 'The domain name or IP address of the mongodb host to connect with')
    .default('port', 3001)
    .describe('port', 'The mongodb server port number to connect with')
    .default('db', 'meteor')
    .describe('db', 'The mongodb database to use')
    .default('gridfs', 'gridfs')
    .describe('gridfs', 'The name of the gridfs bucket to use')
    .default('git', 'git')
    .describe('git', 'path to the git executable to use')
    .alias('g','git')
    .describe('name', 'name of repository in gridfs store')
    .default('name', 'repo')
    .alias('n','name')
    .boolean('h')
    .alias('h','help')
    .wrap(null)
    .version((() -> require('../package').version))

# Parse command line args
argv = yargs.parse process.argv
console.dir argv
if argv.h
  yargs.showHelp()
  exit 1

# Make sure git is installed
unless git = which argv.git
  console.error 'git command not found'
  exit 1

# Make sure this is the root of a git repo
unless 'objects' in ls('.git')
  console.error 'Not a valid git repo!'
  exit 1

# If the repo is packed, unpack it
console.log "About to detect packs"
if ls('.git/objects/pack/pack-*.pack').length > 0
  console.log "Packs detected"
  # Move packs to a temp dir to get them out of the repo
  tmpdir = Math.floor(1000000000000*Math.random()).toString(36)
  mkdir tmpdir
  mv '.git/objects/pack/*', "#{tmpdir}/"
  # Unpack them one by one
  for pack in ls "#{tmpdir}/pack-*.pack"
    exec "git unpack-objects < #{pack}"
  # cleanup
  rm '-rf', tmpdir

server = new mongo.Server argv.host, argv.port
db = new mongo.Db argv.db, server, {w:1}
db.open (err) ->
  console.error "Couldn't open database connection, #{err}" if err
  console.log "Connected to mongo!"

  for dir in ls '.git/objects/*/' when dir.length is 15
    console.log "Dir", dir
    for obj in ls dir # when obj.length is 15
      console.log "Obj: #{dir}/#{obj}"

  db.close (err) ->
    console.error "Couldn't close database connection, #{err}" if err
    console.log "Disconnected from mongo!"

copyObjects = () ->
  console.log "Copying Objects!"
