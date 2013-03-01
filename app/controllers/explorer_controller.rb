require 'rubygems'
require 'mongo'
include Mongo

class ExplorerController < ApplicationController
  before_filter :check_mongo_blacklist

  def index
    respond_to do |format|
      text = "OK"
      if params.has_key?(:db)
        database = MongoMapper.connection.database_names
        for db in database
          if db.casecmp(params[:db]) == 0
            text = "Duplicate"
            break
          end
        end    
      end
      format.json { render json: text}
      format.html 
    end
  end

  def show
  end
  


  def edit
    if params.has_key?(:db)
      if params[:db].empty?
        flash[:error] = "Database name can't be empty.."
        render "explorer/index"
        return
      elsif params[:db].match(/([\/\\\. $])/)
        flash[:error] = "Database name can't have invalid characters."
        render "explorer/index"
        return
      else
        flash[:error]  = false
        database = MongoMapper.connection.database_names
        for db in database
          if db.casecmp(params[:db]) == 0
            flash[:error] = "Database already exists in the system."
            render "explorer/index"
            return
          end
        end
        cl = Mongo::MongoClient.new
        database = cl.db('admin')
        database.command({:copydb => 1, :fromdb => current_database_name, :todb => params[:db]})
        current_database_name = params[:db]
        flash[:info] = "The database was copied successfully"
        redirect_to explorer_path(current_database_name)
        return
      end
    end
    
    render "explorer/index"
    return
  end

  def destroy
    if params.has_key?(:id)
      if !params[:id].empty?
        flash[:error]  = false
        database = MongoMapper.connection.database_names
        for db in database
          if db.casecmp(params[:id]) == 0
            MongoMapper.connection.drop_database(params[:id])
            current_database_name = ""
            current_database = ""
            flash[:info] = "The database was deleted successfully"
            redirect_to explorer_path(current_database_name)
            return
          end
        end
          flash[:error] = "The database has already been deleted."
        render "explorer/index"
      end
    end
    return
  end

  def create
    begin
      if params.has_key?(:db)
        if params[:db].empty?
          flash[:error] = "Database name can't be empty.."
          render "explorer/index"
          return
        elsif params[:db].match(/([\/\\\. $])/)
          flash[:error] = "Database name can't have invalid characters."
          render "explorer/index"
          return
        else
          flash[:error]  = false
          database = MongoMapper.connection.database_names
          for db in database
            if db.casecmp(params[:db]) == 0
              flash[:error] = "Database already exists in the system."
              render "explorer/index"
              return
            end
          end
          current_database  = Connection.new.db(params[:db])
          coll = current_database.collection('temp')   
          coll.remove
          current_database_name = params[:db]
          flash[:info] = "The database was added successfully"
          redirect_to explorer_path(current_database_name)
          return
        end
      end
    rescue Exception =>e
      flash[:error] = "There seems to be some issue. We shall get back to you shortly."
      render "explorer/index"
    end
  end

  protected
    def check_mongo_blacklist
      if current_database_name && !can_read_database?
        render "shared/blacklist"
        return
      end
      if current_collection_name && !can_read_collection?
        render "shared/collection_blacklist"
        return
      end
    end

    def require_edit_access
      if current_database_name && current_collection_name
        unless can_edit_collection?
          render "shared/collection_blacklist"
          return
        end
      elsif current_database_name
        unless can_edit_database?
          render "shared/blacklist"
          return
        end
      end
    end
  end
