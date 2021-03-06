require 'fog/core/model'

module Fog
  module Compute
    class Octocloud

      class Cube < Fog::Model

        def self.setup_default_attributes

          identity :name

          attribute :source
          attribute :md5

          # These are the 'octocloud' ones. Get some commonality!
          # identity :id
          # attribute :url
          # attribute :revision
        end

        # Gets the ID for a named cube, or nil if it doesn't exist.
        protected

        def file_md5(path)
          path = Pathname.new(path).expand_path
          if path.exist?
            Digest::MD5.file(path.to_s).hexdigest
          end
        end
      end

      class LocalCube < Cube
        setup_default_attributes

        def save
          requires :name, :source
          source_md5 = file_md5(source)
          if exist_cube = service.cubes.get(name)
            if exist_cube.md5 == source_md5
              # Nothing has changed, bail
              return
            else
              # Kill it, so we can re-import
              exist_cube.destroy
            end
          end
          service.local_import_box(name, source, source_md5)
        end

        def destroy
          requires :name
          service.local_delete_box(name)
          true
        end
      end

      class RemoteCube < Cube
        setup_default_attributes

        attribute :remote_id, :aliases => 'id'
        attribute :revision

        def save
          requires :name, :source

          data = {}

          attrs = {'name' => identity}

          # ensure if we already match a remote cube, we fetch the remote_id
          if !remote_id && existcube = service.cubes.get(name)
            remote_id = existcube.remote_id
            # ensure we have the right md5 while we're at it
            md5 = existcube.md5
          end

          if remote_id  # we're updating
            # check if the source has been specified. If it has, we only only upload if the md5 differs
            # if it hasn't, submit the metadata for revision
            if source && (new_md5 = file_md5(source)) != md5
              service.remote_upload_cube(remote_id, source)
              data = service.remote_update_cube(remote_id, attrs.merge({:md5 => new_md5}))
            elsif !source
              data = service.remote_update_cube(remote_id, attrs)
            else
              # noop
            end
          else
            begin
              data = service.remote_create_cube(attrs)
              md5 = file_md5(source)
              service.remote_upload_cube(data['id'], source)
              service.remote_update_cube(data['id'], {:md5 => md5})
            rescue Exception => e
              service.remote_delete_cube(data['id'])
              raise e
            end

          end
          merge_attributes(data)
          true

        end

        def destroy
          requires :remote_id
          service.remote_delete_cube(remote_id)
          true
        end


      end

    end
  end
end
