# Submit a proposal
direct_democracy_os.submit_proposal("Build Mars Habitat", "Let's build a habitat on Mars!", "Player1")

# Vote on a proposal
direct_democracy_os.vote_on_proposal("Build Mars Habitat", "Player2", true)

# Request a resource
resource_commons.request_resource("Platinum", 100, "Player1")

# Check resource stock
var platinum_stock = resource_commons.get_resource_stock("Platinum")
print("Platinum stock: ", platinum_stock)