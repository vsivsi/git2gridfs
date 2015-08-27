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
    .default('gridfs', 'fs')
    .describe('gridfs', 'The name of the gridfs bucket to use')
    .default('git', 'git')
    .describe('git', 'path to the git executable to use')
    .alias('g', 'git')
    .describe('name', 'name of repository in gridfs store')
    .default('name', 'repo')
    .alias('n', 'name')
    .describe('chunksize', 'gridfs chunksize to use when writing to the filestore')
    .default('chunksize', 2*1024*1024 - 1024)
    .alias('c', 'chunksize')
    .boolean('h')
    .alias('h', 'help')
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
  grid = new gfs db, mongo, argv.gridfs
  objList = []
  for dir in ls '.git/objects/*/' when dir.length is 15
    for obj in ls dir # when obj.length is 15
      console.log "Obj: #{dir}/#{obj}"
      objList.push "#{dir}/#{obj}"
  console.dir objList

  doIt = (obj, cb) ->
    console.log "Doin' it for #{argv.name}#{obj}"
    # Check for object in gridfs
    grid.exist { _id: "#{argv.name}#{obj}" }, (err, found) ->
      if err or found
        return cb err, found
      console.log "Copying! #{found}"
      grid.createWriteStream
          _id: "#{argv.name}#{obj}"
          filename: "#{argv.name}#{obj}"
          content_type: 'application/octet-stream'
          alias: []
          metadata: {}
          chunkSize: argv.chunksize
          mode: 'w'
        ,
          (err, ws) ->
            return cb err if err
            rs = fs.createReadStream obj
            rs.pipe(ws)
            ws.on 'error', (err) ->
              cb err
            ws.on 'close', (file) ->
              console.log "Wrote file:"
              console.dir file
              ws.lockReleased (err, ld) ->
                cb null, file

  async.series [
    (cb) ->
      async.eachLimit objList, 1, doIt, cb
  ] , (err) ->
    throw err if err
    db.close (err) ->
      console.error "Couldn't close database connection, #{err}" if err
      console.log "Disconnected from mongo!"
