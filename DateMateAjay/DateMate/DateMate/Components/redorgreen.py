import random
import requests
import json

class PerplexityPromptGenerator:
    def __init__(self, api_key):
        self.url = "https://api.perplexity.ai/chat/completions"
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }

    def generate_prompts(self, prompt_type, count):
        prompt = f"Generate {count} unique {prompt_type} in relationships, each as a short phrase."
        
        payload = {
            "model": "llama-3.1-sonar-small-128k-online",
            "messages": [
                {
                    "role": "system",
                    "content": "Be precise and concise."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": 0.7,
            "max_tokens": 200,
            "top_p": 0.9,
            "stream": False
        }

        response = requests.post(self.url, json=payload, headers=self.headers)
        if response.status_code == 200:
            content = json.loads(response.text)['choices'][0]['message']['content']
            return [flag.strip() for flag in content.split('\n') if flag.strip()]
        else:
            print(f"Error: {response.status_code}")
            return []

class RelationshipFlagGame:
    def __init__(self, api_key):
        self.prompt_generator = PerplexityPromptGenerator(api_key)
        self.red_flags = self.prompt_generator.generate_prompts("red flags", 7)
        self.green_flags = self.prompt_generator.generate_prompts("green flags", 7)

    def generate_flags(self):
        flags = []
        for _ in range(5):
            if random.choice([True, False]):
                flag = random.choice(self.red_flags)
                flags.append(("Red flag", flag))
                self.red_flags.remove(flag)
            else:
                flag = random.choice(self.green_flags)
                flags.append(("Green flag", flag))
                self.green_flags.remove(flag)
        return flags

    def play_game(self):
        print("Welcome to the 'Red or Green Flag?' Game!")
        print("I'll present you with 5 relationship flags. You decide whether each is a red flag or a green flag.")
        print("Let's begin!\n")
        
        flags = self.generate_flags()
        correct_answers = 0
        total_questions = len(flags)
        
        for i, (flag_type, flag_description) in enumerate(flags, 1):
            print(f"Flag {i}: {flag_description}")
            user_answer = input("Is this a red flag or a green flag? (Type 'red' or 'green'): ").strip().lower()
            
            while user_answer not in ['red', 'green']:
                user_answer = input("Please type 'red' or 'green': ").strip().lower()
            
            correct_type = flag_type.lower().split()[0]
            if user_answer == correct_type:
                print("Correct!")
                correct_answers += 1
            else:
                print(f"Sorry, that's incorrect. This is actually a {flag_type}.")
            print()
        
        print(f"Game over! You got {correct_answers} out of {total_questions} correct!")
        
        feedback_prompt = f"Generate encouraging feedback for a player who got {correct_answers} out of {total_questions} correct in a relationship flag identification game."
        feedback = self.prompt_generator.generate_prompts(feedback_prompt, 1)[0]
        print(feedback)

if __name__ == "__main__":
    api_key = "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"  # Replace with your actual API key
    game = RelationshipFlagGame(api_key)
    game.play_game()