module.exports = {
  apps : [{
    name   : "inventory",
    script : "ruby ./inventory.rb"
  }, {
    name   : "static",
    script : "../simple-express/app.js"
  }]
}
