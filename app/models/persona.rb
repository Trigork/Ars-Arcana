class Persona < ActiveRecord::Base
	extend FriendlyId
	friendly_id :name, use: :slugged
	belongs_to :arcana
	has_many :special_fusions

	def fusion_cost(fusion)
    	cost = 0
    	fusion.each do |ingr|
    		level = ingr.base_level
    		cost += (27 * level * level) + (126 * level) + 2147
    	end
    	return cost
    end

	def fuse2(persona1, persona2)
		arcana1 = @arc_all.select{|a| a.id == persona1.arcana_id}.first
		arcana2 = @arc_all.select{|a| a.id == persona2.arcana_id}.first

		level = 1 + ((persona1.base_level + persona2.base_level)/2).floor
		arcana = @combos2.select{|c2| (c2.arcana1_id == arcana1.id && c2.arcana2_id == arcana2.id) || (c2.arcana1_id == arcana2.id && c2.arcana2_id == arcana1.id)}
		personas = @per_all.select{|p| p.arcana_id == arcana.first.result_arcana_id}

		i = 0
		personas.each do |per|
			if (per.base_level >= level)
				next if @sp_fus_all.select{|sp| sp.persona_id == per.id}.length != 0
				break
			end
			i += 1
		end

		if (arcana1 == arcana2)
			i -= 1
		end

		if (personas[i] == persona1 || personas[i] == persona2)
			i -= 1
		end

		return personas[i]
	end

	def fuse3(persona1, persona2, persona3)
		arcana1 = @arc_all.select{|a| a.id == p1.arcana_id}
		arcana2 = @arc_all.select{|a| a.id == p2.arcana_id}
		arcana3 = @arc_all.select{|a| a.id == p3.arcana_id}

		level = 5 + ((persona1.base_level + persona2.base_level + persona3)/3).floor
		arcana = @combos2.select{|c2| (c2.arcana1_id == arcana1.id && c2.arcana2_id == arcana2.id) || (c2.arcana1_id == arcana2.id && c2.arcana2_id == arcana1.id)}
		arcana_final = @combos3.select{|c3| c3.arcana1_id == arcana1.id && c3.arcana2_id == arcana2.id}
		personas = @per_all.select{|p| p.arcana_id == arcana_final.first.result_arcana_id}

		found = false
		i = 0
		personas.each do |per|
			if (per.base_level >= level)
				next if @sp_fus_all.select{|sp| sp.persona_id == per.id}.length != 0
				found = true
				break
			end
			i += 1
		end
		return nil if !found

		if(arcana1 == arcana && arcana2 == arcana && arcana3 == arcana)
			while (persona1.name == personas[i].name || persona2.name == personas[i].name || persona3.name == personas[i].name)
				i += 1
				return nil if (!personas[i])
			end
		end

		return personas[i]
	end

	def filter2Way(persona1, persona2, result)
    	return true if (persona1.name == self.name)
   		return true if (persona2.name == self.name)
    	return false if (result.name == self.name)
    	return true
    end

	def persona_recipes2(arcana)
		recipes = []
		combos = @combos2.select{|c2| c2.result_arcana_id == arcana.id}
		combos.each do |combo|
			personas1 = @per_all.select{|p| p.arcana_id == combo.arcana1_id}
			personas2 = @per_all.select{|p| p.arcana_id == combo.arcana2_id}
			personas1.each do |p1|
				ar1 = @arc_all.select{|a| a.id == p1.arcana_id}
				personas2.each do |p2|
					ar2 = @arc_all.select{|a| a.id == p2.arcana_id}
					next if ar1 == ar2
					result = fuse2(p1,p2)
					next if !result
					next if filter2Way(p1,p2,result)
					recipes << {:cost => fusion_cost([p1, p2]), :ingr => [p1.id, p2.id]}
				end
			end
		end
		return recipes
	end

	def persona_recipes3(arcana1, arcana2)
		recipes = []
		step1Recipes = persona_recipes2(arcana1)
		step1Recipes.each do |s1Recipe|
			p1 = @per_all.select{|p| p.arcana_id == s1Recipe.arcana1_id}
			p2 = @per_all.select{|p| p.arcana_id == s1Recipe.arcana2_id}
			personas = @per_all.select{|p| p.arcana_id == arcana2.id}
			pers.each do |p3|
				if persona3IsValid(p1,p2,p3)
					result = fuse3(p1,p2,p3)
					next if (!result || result.name != self.name)
					recipes << {:cost => fusion_cost([p1, p2, p3]), :ingr => [p1.id, p2.id, p3.id]}
				end
			end
		end
		return recipes
	end

	def persona3IsValid(p1,p2,p3)
		ar1 = @arc_all.select{|a| a.id == p1.arcana_id}
		ar2 = @arc_all.select{|a| a.id == p2.arcana_id}
		ar3 = @arc_all.select{|a| a.id == p3.arcana_id}

		return false if (p3 == p1)
		return false if (p2 == p1)

		return false if (p3.base_level < p1.base_level)
		return false if (p3.base_level < p2.base_level)

		if p3.base_level == p1.base_level
			return ar3.IntNumber < ar1.IntNumber
		end

		if p3.base_level == p2.base_level
			return ar3.IntNumber < ar2.IntNumber
		end

		return true
	end

	def get_recipes
		@combos2 = ArcanaFusionTwo.all
		@combos3 = ArcanaFusionThree.all
		@arc_all = Arcana.all
		@per_all = Persona.all
		@sp_fus_all = SpecialFusion.all

		recipes = []
		self_arcana = @arc_all.select{|a| a.id == self.arcana_id}.first

		recipes = persona_recipes2(self_arcana)
		combos = @combos3.select{|c3| c3.result_arcana_id == self_arcana.id}

		combos.each do |combo|
			arcana1 = @arc_all.select{|a| a.id == combo.arcana1_id}.first
			arcana2 = @arc_all.select{|a| a.id == combo.arcana2_id}.first
			recipes << persona_recipes3(arcana1, arcana2)
			if combo.arcana2_id != combo.arcana1_id
				recipes << persona_recipes3(arcana2, arcana1)
			end
		end

		return recipes
	end
end