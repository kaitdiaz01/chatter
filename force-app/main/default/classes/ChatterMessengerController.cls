public with sharing class ChatterMessengerController {
    // to get conversations from event 
    @AuraEnabled(cacheable=true)
    public static List<Conversation> getConversations() {
        ConnectApi.ChatterConversationPage page = ConnectApi.ChatterMessages.getConversations();
        List<Conversation> result = new List<Conversation>();
        for (ConnectApi.ChatterConversationSummary conv : page.conversations) {
            result.add(new Conversation(conv));
        }
        return result;
    }

    // to get and set Id for messages in conversation
    @AuraEnabled(cacheable=true)
    public static List<Message> getConversation(String convId) {
        if (String.isBlank(convId)) {
            return new List<Message>();
        }
        ConnectApi.ChatterConversation page = ConnectApi.ChatterMessages.getConversation(
            convId
        );
        List<Message> result = new List<Message>();
        for (ConnectApi.ChatterMessage msg : page.messages.messages) {
            result.add(new Message(msg));
        }
        return result;
    }

    // get message 
    @AuraEnabled
    public static Message replyToMessage(String text, String msgId) {
        ConnectApi.ChatterMessage msg = ConnectApi.ChatterMessages.replyToMessage(
            text,
            msgId
        );
        return new Message(msg);
    }


    @AuraEnabled
    public static Message sendMessage(String text, String recipients) {
        ConnectApi.ChatterMessage msg = ConnectApi.ChatterMessages.sendMessage(
            text,
            recipients
        );
        return new Message(msg);
    }

    // get users Id when searching 
    @AuraEnabled(cacheable=true)
    public static List<User> searchUsers(String query) {
        ConnectApi.UserPage users = ConnectApi.ChatterUsers.searchUsers(
            null,
            query
        );
        // set user Ids
        List<User> result = new List<User>();
        for (ConnectApi.UserDetail user : users.users) {
            if (UserInfo.getUserId() != user.id) {
                result.add(new User(user));
            }
        }
        return result;
    }

    @AuraEnabled
    public static void publishNewMessageEvent(
        String conversationId,
        String messageId
    ) {
    // publish platform event using EventBus utility class 
        EventBus.publish(
            new ChatterMessageEvent__e(
                conversationId__c = conversationId,
                messageId__c = messageId
            )
        );
    }

    public class User {
        @AuraEnabled
        public String id { get; private set; }
        @AuraEnabled
        // had to make name public to get names to show up in UI
        public String name { get; set; }
        @AuraEnabled
        String smallPhotoUrl { get; set; }
        @AuraEnabled
        String companyName { get; set; }
        @AuraEnabled
        String title { get; set; }

        public User(ConnectApi.User user) {
            this.id = user.id;
            this.name = user.displayName;
            this.smallPhotoUrl = user.photo.smallPhotoUrl;
            this.companyName = user.companyName;
            this.title = user.title;
        }
    }

    public class Conversation {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String formattedRecipientNames { get; set; }
        @AuraEnabled
        public Datetime sentDate { get; set; }
        @AuraEnabled
        public String message { get; set; }
        @AuraEnabled
        public String smallPhotoUrl { get; set; }
        @AuraEnabled
        public String latestMessageId { get; set; }

        public Conversation(ConnectApi.ChatterConversationSummary conv) {
            this.id = conv.id;
            this.sentDate = conv.latestMessage.sentDate;
            this.message = conv.latestMessage.body.text;
            this.smallPhotoUrl = conv.latestMessage.sender.photo.smallPhotoUrl;
            this.latestMessageId = conv.latestMessage.id;
            this.formattedRecipientNames = '';
            for (ConnectApi.UserSummary user : conv.members) {
                if (UserInfo.getUserId() != user.id) {
                    this.formattedRecipientNames += user.displayName + ', ';
                }
            }
            this.formattedRecipientNames = this
                .formattedRecipientNames.removeEnd(', ');
        }
    }

    public class Message {
        Datetime sentDate { get; set; }
        @AuraEnabled
        public String id { get; private set; }
        @AuraEnabled
        public String conversationId { get; private set; }
        @AuraEnabled
        String sender { get; set; }
        @AuraEnabled
        String formattedSentDate { get; set; }
        @AuraEnabled
        String text { get; set; }
        @AuraEnabled
        String smallPhotoUrl { get; set; }
        @AuraEnabled
        Boolean isMine { get; set; }
        @AuraEnabled
        List<String> recipients { get; set; }

        public Message(ConnectApi.ChatterMessage msg) {
            this.id = msg.id;
            this.conversationId = msg.conversationId;
            this.sender = msg.sender.name;
            this.sentDate = msg.sentDate;
            this.formattedSentDate = msg.sentDate.format();
            this.text = msg.body.text;
            this.smallPhotoUrl = msg.sender.photo.smallPhotoUrl;
            this.isMine = (UserInfo.getUserId() == msg.sender.id);

            this.recipients = new List<String>();
            if (!msg.recipients.isEmpty()) {
                for (ConnectApi.UserSummary recipient : msg.recipients) {
                    this.recipients.add(recipient.id);
                }
            }
        }
    }
}
