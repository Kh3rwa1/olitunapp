import os

def main():
    workspace = "/Users/dulorai/olitun/olitunapp"
    words_file = os.path.join(workspace, "lib/shared/providers/words_provider.dart")
    seeds_file = os.path.join(workspace, "scratch/missing_seeds.dart")
    
    with open(words_file, "r", encoding="utf-8") as f:
        words_content = f.read()
        
    with open(seeds_file, "r", encoding="utf-8") as f:
        seeds_content = f.read()
        
    # We want to replace:
    #     WordModel(
    #       id: 'w_fd20',
    #       wordOlChiki: 'ᱦᱚᱲᱮᱡ',
    #       wordLatin: 'Horej',
    #       meaning: 'Black gram beans',
    #       category: 'food',
    #       order: 200,
    #     ),
    #   ];
    #
    # with that plus seeds_content
    
    target = """    WordModel(
      id: 'w_fd20',
      wordOlChiki: 'ᱦᱚᱲᱮᱡ',
      wordLatin: 'Horej',
      meaning: 'Black gram beans',
      category: 'food',
      order: 200,
    ),
  ];"""

    replacement = """    WordModel(
      id: 'w_fd20',
      wordOlChiki: 'ᱦᱚᱲᱮᱡ',
      wordLatin: 'Horej',
      meaning: 'Black gram beans',
      category: 'food',
      order: 200,
    ),
\n""" + seeds_content + "\n  ];"

    if target in words_content:
        new_content = words_content.replace(target, replacement)
        with open(words_file, "w", encoding="utf-8") as f:
            f.write(new_content)
        print("Successfully appended seeds to words_provider.dart!")
    else:
        # Fallback: try with different newline formatting if any
        target_normalized = target.replace("\r\n", "\n")
        words_content_normalized = words_content.replace("\r\n", "\n")
        if target_normalized in words_content_normalized:
            new_content = words_content_normalized.replace(target_normalized, replacement)
            with open(words_file, "w", encoding="utf-8") as f:
                f.write(new_content)
            print("Successfully appended seeds (normalized) to words_provider.dart!")
        else:
            print("ERROR: Target sequence not found in words_provider.dart")

if __name__ == "__main__":
    main()
