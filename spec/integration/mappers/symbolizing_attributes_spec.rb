require 'spec_helper'

describe 'Mappers / Symbolizing atributes' do
  let(:setup) { ROM.setup(memory: 'memory://test') }
  let(:rom) { setup.finalize }

  before do
    setup.schema do
      base_relation(:users) do
        repository :memory

        attribute 'user_id'
        attribute 'first_name'
        attribute 'email'
      end

      base_relation(:tasks) do
        repository :memory

        attribute 'title'
        attribute 'task_priority'
        attribute 'task_description'
      end
    end
  end

  it 'automatically maps all attributes using top-level settings' do
    setup.mappers do
      define(:users, symbolize_keys: true, inherit_header: false, prefix: 'user') do
        attribute :id

        wrap :details, prefix: 'first' do
          attribute :name
        end

        wrap :contact, prefix: false do
          attribute :email
        end
      end
    end

    rom.schema.users << {
      'user_id' => 123,
      'first_name' => 'Jane',
      'email' => 'jane@doe.org'
    }

    jane = rom.read(:users).first

    expect(jane).to eql(
      id: 123, details: { name: 'Jane' }, contact: { email: 'jane@doe.org' }
    )
  end

  it 'automatically maps all attributes using settings for wrap block' do
    setup.mappers do
      define(:tasks, symbolize_keys: true) do
        attribute :title

        wrap :details, prefix: 'task' do
          attribute :priority
          attribute :description
        end
      end
    end

    rom.schema.tasks << {
      'title' => 'Task One',
      'task_priority' => 1,
      'task_description' => 'It is a task'
    }

    task = rom.read(:tasks).first

    expect(task).to eql(
      title: 'Task One',
      details: { priority: 1, description: 'It is a task' }
    )
  end
end
