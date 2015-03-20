# Git Pivotal Tracker Integration
# Copyright (c) 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module GitPivotalTrackerIntegration
  module Command

    class Report < Base

      def run(args)
        owned_by = "Jeff Wolski" # hard coded to Jeff Wolski for now

        $LOG.debug("#{self.class} in project:#{@project.name} pwd:#{pwd} branch:#{Util::Git.branch_name}")
        bug_title = nil
        bug_title = args[0] if args.length == 1

        # puts bug_title
        if bug_title.nil? || bug_title.empty?
          abort "\nUsage example:\n\n git report \"Issue running deliver command\" \n"
        end

        report_note = ""
        while (report_note.nil? || report_note.empty?)
          report_note = ask("Description of bug:")
        end

        current_user        = (Util::Shell.exec "git config user.name").chomp
        bug_title           = "User Reported - #{current_user} - #{bug_title}"
        current_user_email  = (Util::Shell.exec "git config user.email").chomp
        bug_description     = "#{@project.name}\n#{current_user_email}\n#{report_note}"

        project = @client.project(1067990)

        story_params = {:owned_by => owned_by, :story_type => "bug",
                        :name => bug_title,    :description => bug_description,
                        :labels => "userreported"}

        project.create_story

        uploaded_story.upload_attachment(self.logger_filename)
      end

    end

  end
end
