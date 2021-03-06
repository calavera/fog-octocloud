module Fog
  module Compute
    class OVFTool
      TOOL = `which ovftool`.empty? ? "/Applications/VMware\\ Fusion.app//Contents/Library/VMware\\ OVF\\ Tool/ovftool" : `which ovftool`.strip

      def self.run(cmd, opts = '')
        res = `#{TOOL} #{opts} #{cmd}`
        if $? == 0
          return res
        else
          raise "Error running ovftool command #{cmd}: " + res
        end
      end

      def self.convert(src, dst, opts = {})
        cmd_opts = []
        cmd_opts << '--lax' if opts[:lax]
        run("#{cmd_opts.join(' ')} #{src} #{dst}")
      end

    end
  end
end
