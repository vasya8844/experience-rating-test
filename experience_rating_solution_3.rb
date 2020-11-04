# == Schema Information
#
# Table name: experiences
#
# id :integer, not null, primary key
# name :string

# Table name: vote_questions
#
# id :integer, not null, primary key
# question :string

# Table name: votes
#
# id :integer, not null, primary key
# vote_question_id :integer, not null
# experience_id :integer, not null
# vote :integer, not null
# ip :string

# Indexes
#
# index_votes_unique_tripple (vote_question_id, experience_id, ip), unique: true
# index_votes_experience_id (experience_id)
# index_votes_vote_question_id (vote_question_id)

# Foreign Keys
#
#  fk_rails_...  (votes.vote_question_id => vote_questions.id)
#  fk_rails_...  (votes.experience_id => experiences.id)

class Experience < ActiveRecord
  has_many :votes

  def rating(vote_question)
    cached_key = "experince_vote_rating_#{id}_#{vote_question.id}"

    # TODO: need to be imlemented
    value = get_cached_value_from_redis(cached_key)

    unless value
      # TODO: need to reassure that averate syntax is correct in this case
      value = votes.per_question(vote_question).average(:vote)

      set_cached_value_from_redis(cached_key, value, 1.hour) # 1.hour time to live
    end

    value
    # TODO: possible model is not the best place to calculation aroung cache
  end

end

class VoteQuestion < ActiveRecord
  has_many :votes
end

class Vote < ActiveRecord
  belongs_to :vote_question
  belongs_to :experience

  scope :per_question, -> { |vote_question_id| where(:vote_question_id => vote_question_id)}
end

# Cons: in this case need to extract `score or grade` votes into separated table
# Now we can store rating `per experience per vote question`

# Pros: tried to implement more generic way to do experience voting
