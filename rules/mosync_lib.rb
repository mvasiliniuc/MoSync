# Copyright (C) 2009 Mobile Sorcery AB
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 2, as published by
# the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the Free
# Software Foundation, 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

# This file defines helper classes used for compiling MoSync libraries for both
# native and pipe platforms.
# To use, call MoSyncLib.invoke with a module
# which has the setup_native and setup_pipe methods defined.

require "#{File.dirname(__FILE__)}/dll.rb"
require "#{File.dirname(__FILE__)}/pipe.rb"

MOSYNC_INCLUDE = "#{ENV['MOSYNCDIR']}/include"
MOSYNC_LIBDIR = "#{ENV['MOSYNCDIR']}/lib"

module MoSyncMod
	def modSetup
		@EXTRA_INCLUDES = @EXTRA_INCLUDES.to_a + [MOSYNC_INCLUDE]
	end
	
	def copyHeaders
		dir = MOSYNC_INCLUDE + "/" + @INSTALL_INCDIR
		DirTask.new(self, dir).invoke
		# create a bunch of CopyFileTasks, then invoke them all.
		collect_headers(".h").each do |h|
			task = CopyFileTask.new(self, dir + "/" + File.basename(h.to_s), h)
			task.invoke
		end
	end
	
	private
	
	def collect_headers(ending)
		files = @SOURCES.collect {|dir| Dir[dir+"/*"+ending]}
		files.flatten!
		if(defined?(@IGNORED_HEADERS))
			files.reject! {|file| @IGNORED_HEADERS.member?(File.basename(file))}
		end
		return files.collect do |file| FileTask.new(self, file) end
	end
end

class MoSyncDllWork < DllWork
	include MoSyncMod
	def setup
		setup_native
		modSetup
		if(HOST == :win32)
			@EXTRA_LINKFLAGS = @EXTRA_LINKFLAGS.to_s + " -Wl,--enable-auto-import"
		end
		@EXTRA_CFLAGS = @EXTRA_CFLAGS.to_s + " -D_POSIX_SOURCE"	#avoid silly bsd functions
		copyHeaders
		super
	end
end

class PipeLibWork < PipeGccWork
	include MoSyncMod
	def setup
		@FLAGS = " -L"
		setup_pipe
		modSetup
		copyHeaders
		super
	end
	def setup3(all_objects)
		@TARGET_PATH = MOSYNC_LIBDIR + "/pipe/" + @CONFIG_NAME + "/" + @NAME + ".lib"
		super(all_objects)
	end
	#def filename; @NAME + ".lib"; end
end

module MoSyncLib end

def MoSyncLib.inin(work, mod)
	work.extend(mod)
	work.invoke
end

def MoSyncLib.invoke(mod)
	target :pipe do
		MoSyncLib.inin(PipeLibWork.new, mod)
	end
	target :native do
		MoSyncLib.inin(MoSyncDllWork.new, mod)
	end
	target :default => [:pipe, :native]
	
	Targets.invoke
end
