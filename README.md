[![Build Status](https://travis-ci.org/brandonblack/mongo-tools.png)](https://travis-ci.org/brandonblack/mongo-tools) [![Code Climate](https://codeclimate.com/github/brandonblack/mongo-tools.png)](https://codeclimate.com/github/brandonblack/mongo-tools) [![Dependency Status](https://gemnasium.com/brandonblack/mongo-tools.png)](https://gemnasium.com/brandonblack/mongo-tools) [![Coverage Status](https://coveralls.io/repos/brandonblack/mongo-tools/badge.png?branch=master)](https://coveralls.io/r/brandonblack/mongo-tools)

Overview
==========

This project is an effort to combine existing community projects as well as new MongoDB related tools into a single, easily redistributable application.

Features:

* Database Visualizer
* Query Analyzer
* Log Explorer
* Database Explorer
* Query Interface
* Document Editor
* REST API
* Notification & Alerts

Getting Started
============

Follow these steps to get started with mongotools.

1. Clone the mongotools repo and navigate to your local cloned copy.
2. Create the mongo dir to hold the log files.  
`$ mkdir ~/mongo`
3. Run the setup wizard to create the stats db.  
`$ rake setup:server`
4. Start mongotools.  
`$ bundle exec rails s`

Troubleshooting:

Double check the connection settings located in:  
`/config/application.yml`

If the above fails, try:  
`$ mongod --dbpath ~/mongo --port 27018  --fork --logpath ~/mongo/logs`
