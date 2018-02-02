_ = require 'lodash'
fs = require 'fs'
path = require 'path'


isFile = (path)->
  new Promise (resolve, reject)->
    fs.stat path, (err, stats)->
      if err then return reject err
      if stats.isFile()
        resolve()
      else
        reject "not file: #{path}"

isDir = (path)->
  new Promise (resolve, reject)->
    fs.stat path, (err, stats)->
      if err then return reject err
      if stats.isDirectory()
        resolve()
      else
        reject "not dir: #{path}"


readAs = (encode)->(file_path) ->
  isFile(file_path).then ()->
    new Promise (resolve, reject)->
      encode = encode or 'utf8'
      fs.readFile file_path, encode, (err, data)->
        if err then return reject err
        resolve data

readAsUtf8 = (file_path)->
  readAs('utf8')(file_path)

read = readAsUtf8

writeAs = (encode)->(file_path, data)->
  ensureExistDir(path.dirname(file_path)).then ()->
    new Promise (resolve, reject)->
      options =
        encoding: 'utf8'
        mode: 0o666
        flag: 'w'
      if typeof encode == 'string'
        options.encoding = encode
      fs.writeFile file_path, data, options, (err)->
        if err then return reject err
        resolve "wrote: #{file_path}"

writeAsUtf8 = (file_path, data)->
  writeAs('utf8')(file_path, data)

write = writeAsUtf8

ensureExistDir = (dir, mask) ->
  new Promise (resolve, reject)->
    mask = mask or 0o755
    fs.mkdir dir, mask, (err) ->
      if err
        if err.code == 'EEXIST'
          resolve 'EEXIST'
        else if err.code == 'ENOENT'
          ensureExistDir(path.dirname(dir), mask).then ()-> ensureExistDir(dir, mask)
        else
          # something wrong.
          reject err
      else
        resolve "created: #{dir}"

prepareCleanDir = (abs_dir_path) ->
  ensureExistDir(abs_dir_path).then ()->
    delAllFilesInDir(abs_dir_path)

catalogueDir = (dir, expression) ->
  isDir(dir).then ()->
    new Promise (resolve, reject)->
      fs.readdir dir, (err, files) ->
        if err then return reject "err: catalogueDir: #{err}"
        resolve _.filter files, (file) -> file.match(expression)

unlink = (path)->
  new Promise (resolve, reject)->
    fs.stat path, (err, stats)->
      if err then return resolve err
      # dont care path is dir or file
      if stats.isFile() or stats.isDirectory()
        fs.unlink path, (err, result)->
          if err then return reject err
          resolve result
      else
        resolve "#{path} is not file or dir"

delete_file = (file_path)->
  isFile(file_path).then ()->
    unlink(file_path)
  .catch (err)->
    Promise.resolve err

delAllFilesInDir = (dir) ->
  catalogueDir(dir, /.+/).then (file_list)->
    Promise.all(file_list.map (file)-> delete_file(dir+file)).then ()->
      "#{file_list.length} files deleted."

appendMessageToFile = (file_path, message) ->
  ensureExistDir(path.dirname(file_path)).then () ->
    new Promise (resolve, reject)->
      fs.appendFile file_path, message + '\n', (err, result)->
        if err then return reject err
        resolve result

getCertBinary = (cert_file_path) ->
  readAs('base64').then (cert_binary)->
    new Promise (resolve, reject)->
      if cert_binary
        resolve cert_binary
      else
        reject "has read by base64, but no contents: #{cert_file_path}"

zipAllFileInDir = (dir_path, zipped_file_name)->
  isDir(dir_path).then ()->
    zipped_file_name = zipped_file_name or "#{path.dirname(dir_path)}.zip"
    new Promise (resolve, reject)->
      exec = require('child_process').exec
      exec 'zip -j ' + zipped_file_name + ' ' + dir_path + '*', (err, stdout, stderr) ->
        if err then reject callback(err)
        if stderr
          reject(stderr)
        else
          resolve "zipped: #{zipped_file_name} with message: #{stdout}"

mv = (src_file_path, dst_file_path) ->
  new Promise (resolve, reject)->
    fs.rename src_file_path, dst_file_path, (err, result)->
      if err then return reject err
      resolve result

mv_overwrite = (src_file_path, dst_file_path) ->
  isFile(src_file_path).then ()->
    delete_file_if_exists(dst_file_path).then ()->
      mv src_file_path, dst_file_path

module.exports =
  path: path
  isFile: isFile
  isDir: isDir

  read: read
  readAs: readAs
  write: write
  writeAs: writeAs

  ensureExistDir: ensureExistDir
  prepareDir: ensureExistDir
  prepareCleanDir: prepareCleanDir
  catalogueDir: catalogueDir

  delete_file: delete_file
  delAllFilesInDir: delAllFilesInDir
  mv: mv
  mv_overwrite: mv_overwrite

  appendMessageToFile: appendMessageToFile
  getCertBinary: getCertBinary
  zipAllFileInDir: zipAllFileInDir
