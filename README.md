[![Build Status](https://travis-ci.org/brandonblack/mongo-tools.png)](https://travis-ci.org/brandonblack/mongo-tools)

[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/brandonblack/mongo-tools)

Overview
========

MongoDB is an open source, document-oriented database designed with both scalability and developer agility in mind. Instead of storing your data in tables and rows as you would with a relational database, in MongoDB you store JSON-like documents with dynamic schemas. The goal of MongoDB is to bridge the gap between key-value stores (which are fast and scalable) and relational databases (which have rich functionality).

MongoDB is currently the leading NoSQL database and the company behind it, 10gen, develops MongoDB, offers production support, training, and consulting for the open source database.

Experience with MongoDB is a highly sought after skill that many employers are seeking today. Through the work on this project, the students will be able to walk away with a substantial amount of knowledge about MongoDB and document-oriented databases.

More about MongoDB: <http://www.mongodb.org><br>
More about 10gen: <http://www.10gen.com>

Objectives
==========

Our goal for this project is to kick-off a new effort to bring better tooling to MongoDB in an all-in-one, portable, and easy to deploy package. This project will be highly visible, community facing, and our goal is to make it as valuable to MongoDB new comers as it is to veteran users.

There are already a number of existing community-built projects and tools as well as tools for managing MongoDB that have been built by 10gen. We'd like to begin an effort to consolidate some of these tools together into one easily distributed package and develop a few new offerings to be included as well.

Here are a few things we'd eventually like to tackle:

* Replica Set/Shard Visualizer
* Log Visualizer
* Query Analyzer
* mongostat Visualizer
* Database/Collection Explorer
* Enhanced Query Interface
* Document Editor
* REST API

It's not the intention that all or even most of these things get completed during this course, but we'd like to present all the options we've got on our roadmap so that the students involved can select the components that they're most interested in contributing on. 

Requirements
============

This project will be a browser-based application, but the goal is to make it extremely portable, easy to setup and cross-platform compatible. We'll be developing the application using the latest version of Ruby on Rails, and Ruby 1.9 running on the latest version of JRuby.

Installing and running the application should simple and straight forward with few moving parts so we'll be packaging the application up using [Jetpack](https://github.com/square/jetpack) (Jetty) allowing it to be deployed and fired up on any platform or environment with a single command.

Tools we're planning on using:

* Ruby on Rails (3.2.x)
* JRuby 1.7.x (Ruby 1.9)
* Jetpack

Evaluation
==========

At the end of the course, each student will be evaluated based on the following:

* Experience and knowledge gained working with MongoDB.
* Experience and knowledge gained working with the open-source community.
* Overall contribution to the project.

Contacts
========
Bernie Hackett (<bernie@10gen.com>)
Brandon Black (@brandonmblack, <brandon.black@10gen.com>)