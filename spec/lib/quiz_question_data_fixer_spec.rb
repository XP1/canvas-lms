# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe QuizQuestionDataFixer do

  before(:each) do
    @bad = {:correct_comments=>"",
            :question_bank_name=>"Quiz",
            :question_type=>"multiple_choice_question",
            :incorrect_comments=>"",
            :migration_id=>"QUE_1014",
            :points_possible=>nil,
            :question_name=>"test fun",
            :name=>"test fun",
            :answers=>
                    [{:migration_id=>"QUE_1016_A1", :text=>"True", :weight=>nil, :id=>nil},
                     {:migration_id=>"QUE_1017_A2", :text=>"False", :weight=>nil, :id=>nil}],
            :question_text=>
                    "Image yo: <img src=\"/assessment_questions/9270/files/6163/download?verifier=Cu96fSJHUJgVPNHEfoqLomZT64gkEzNP6Rphfl0y\" align=\"bottom\" alt=\"image.png\">"}

    @good = {:correct_comments=>"",
             :question_type=>"multiple_choice_question",
             :question_bank_name=>"Quiz",
             :assessment_question_id=>"9270",
             :migration_id=>"QUE_1014",
             :incorrect_comments=>"",
             :question_name=>"test fun",
             :name=>"test fun",
             :points_possible=>1,
             :question_text=>
                     "Image yo: <img src=\"/courses/117/files/6158/preview\" align=\"bottom\" alt=\"image.png\">",
             :answers=>
                     [{:migration_id=>"QUE_1016_A1", :text=>"True", :weight=>100, :id=>8080},
                      {:migration_id=>"QUE_1017_A2", :text=>"False", :weight=>0, :id=>2279}]}
  end

  it "should fix questions from old version on assessment question" do
    course
    bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
    aq = bank.assessment_questions.create(:question_data => @good)
    aq.migration_id = "yes_i_have_one"
    aq.with_versioning(&:save)
    aq.question_data = @bad
    aq.with_versioning(&:save) # push the good data to a further version

    quiz = @course.quizzes.create!(:title => "test quiz")
    qq = quiz.quiz_questions.create!(:assessment_question => aq)
                               # the QQ still has bad data, but the user had given it a points possible
    qq.write_attribute(:question_data, @bad.merge({:points_possible => 5}))
    qq.save
    qq2 = quiz.quiz_questions.create!(:assessment_question => aq)
    qq2.write_attribute(:question_data, @good.merge({:name => "changed"}))
    qq2.save
    qq3 = quiz.quiz_questions.create!(:assessment_question => aq)
    qq3.write_attribute(:question_data, @bad)
    qq3.save

    QuizQuestionDataFixer.fix_quiz_questions_with_bad_data

    @good[:assessment_question_id] = aq.id

    aq.reload
    aq.question_data.should == @good
    qq.reload
    qq.question_data.should == @good.merge({:points_possible => 5})
    qq2.reload
    qq2.question_data[:name].should == "changed"
    qq3.reload
    qq3.question_data.should == @good
  end

  it "should fix questions from quiz question" do
    course
    bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
    aq = bank.assessment_questions.create(:question_data => @bad)

    quiz = @course.quizzes.create!(:title => "test quiz")
    qq = quiz.quiz_questions.create!(:assessment_question => aq)
    qq.write_attribute(:question_data, @good)
    qq.save
    qq2 = quiz.quiz_questions.create!(:assessment_question => aq)
    qq2.write_attribute(:question_data, @bad)
    qq2.save

    QuizQuestionDataFixer.fix_quiz_questions_with_bad_data

    @good[:assessment_question_id] = aq.id

    aq.reload
    aq.question_data.should == @good
    qq2.reload
    qq2.question_data.should == @good
  end

end