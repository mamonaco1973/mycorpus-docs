# mycorpus User Guide

mycorpus is an AI-powered assistant that answers questions using your organisation's own knowledge base. Instead of generic internet knowledge, every answer is grounded in the specific documents, websites, and content your administrator has loaded into the system.

---

## Getting Started

### What is mycorpus?

mycorpus is a private AI assistant. When you ask a question, mycorpus searches a curated collection of content called a corpus and uses it to generate a grounded, cited answer. You only see answers the system can support from the loaded content — it will not speculate beyond its knowledge base.

### How do I sign up?

Open the mycorpus login page in your browser. Click **Sign Up**, enter your email address and choose a password, then confirm your email if prompted. After signing up, your account may be in a pending state if your administrator runs the system in closed-access mode. In that case, you will see a message asking you to wait for approval. Your administrator will be notified and can grant you access.

If your organisation uses Google login, SAML, or single sign-on, your administrator will have provided a login button on the sign-in page. Use that button instead of creating a separate password.

### How do I log in?

Visit the mycorpus login page. Enter your email and password and click **Sign In**. If Google or SSO login is available, you will see a button for it on the login page. Click that button to authenticate through your identity provider without needing a separate password.

### What if I forget my password?

On the login page, click **Forgot password**. Enter your email address and you will receive a reset link. Follow the link in the email to set a new password. If you use Google or SSO login, password reset is managed by your identity provider, not mycorpus.

---

## Using the Chat Interface

### How do I ask a question?

Type your question in the message box at the bottom of the screen and press Enter or click the send button. mycorpus will search the knowledge base and generate a response. Responses typically arrive within a few seconds, though larger corpora or complex questions may take a moment longer.

### What are starter questions?

When you create a new conversation, you may see a set of suggested starter questions displayed in the chat area. These questions are automatically generated from the content in the knowledge base and are designed to give you a sense of what topics are available. Clicking a starter question sends it as your first message.

### How does mycorpus find answers?

When you submit a question, mycorpus converts it into a mathematical representation and searches the knowledge base for the most relevant passages. It then sends those passages along with your question to an AI language model, which generates a coherent answer. All answers are grounded in the retrieved content — the system does not draw on general internet knowledge outside the corpus.

### Where do the cited sources come from?

Below or alongside each answer, mycorpus shows the source documents it used to construct the response. Sources may include document titles, URLs, repository names, or other identifiers depending on what your administrator has loaded. Reviewing sources lets you verify the answer and read the original material for more detail.

### Can I ask follow-up questions?

Yes. mycorpus remembers the recent history of your conversation and uses it as context when answering follow-up questions. You can ask clarifying questions, request more detail, or ask about a related topic within the same conversation. If you want to start a completely fresh topic without prior context, start a new conversation.

---

## Managing Conversations

### How do I start a new conversation?

Click the **New conversation** button in the left sidebar. Each conversation is independent. Starting a new conversation clears the prior context so your question is answered without reference to previous exchanges.

### Can I see my past conversations?

Yes. The left sidebar lists all your conversations, most recent first. Click any conversation to reopen it and review the full exchange. You can continue asking questions in any previous conversation.

### How do I rename a conversation?

In the sidebar, click the conversation you want to rename. An edit option will appear that lets you set a custom title. Giving conversations meaningful names makes them easier to find later.

### How do I delete a conversation?

In the sidebar, hover over the conversation you want to remove. A delete option will appear. Deleting a conversation is permanent — the questions and answers cannot be recovered.

---

## Token Budget

### What is a token budget?

Every response mycorpus generates consumes tokens. Tokens are the units of text that the AI model processes — roughly one token per word. Your account has a weekly token budget that limits how much you can use in a rolling seven-day window.

### What happens when I run out of tokens?

When your token budget is exhausted, you will see a message indicating that your limit has been reached and when it will reset. You can still browse past conversations but cannot submit new questions until your budget resets.

### When does my token budget reset?

Token budgets reset at 01:00 UTC every Sunday. Usage from the prior week does not carry over — your full budget is available again from that point.

### How can I see how many tokens I have left?

Your remaining token budget is displayed in the interface, typically near your account information or in the sidebar. The display shows tokens used and your weekly limit.

### Why is my token limit different from another user's?

Token budgets are set by your administrator and may vary by account. Administrator and Owner accounts have a higher budget than standard users.

---

## Multiple Corpora

### What is a corpus?

A corpus is a curated collection of content that mycorpus searches to answer questions. Your administrator may have created multiple corpora covering different topics, departments, or projects.

### Can I choose which corpus to search?

If your administrator has set up multiple corpora, you may be able to select which one to use when starting a new conversation. The corpus selector appears when creating a new conversation. Each conversation is tied to the corpus it was started with — you cannot switch corpora mid-conversation.

---

## Account and Privacy

### Who can see my conversations?

Your conversations are private to your account. Administrators can manage user accounts and access but do not have a built-in interface to browse individual user conversations. Your questions and answers are stored in the system but are not shared with other users.

### Is my data used to train AI models?

No. mycorpus uses AWS Bedrock to process your questions. AWS does not use data submitted through Bedrock API calls to train or improve foundation models. Your content is processed in memory during inference and is not retained by the AI service after the response is returned.

### How do I contact support?

Use the **Contact Support** or **Help** link in the interface if one is available. Your administrator configures the support contact address. If no contact link is visible, reach out to your organisation's internal IT or support team.
