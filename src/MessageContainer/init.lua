--!strict

local package = script.Parent;

local React = require(package.Parent.react);
local IDialogue = require(package.Parent["dialogue-types"]);
local IEffect = require(package.Parent["effect-types"]);

local MessageTextSegment = require(script.MessageTextSegment);
local usePages = require(package.Parent["use-pages"]);

type Page = IEffect.Page;
type Dialogue = IDialogue.Dialogue;

export type MessageContainerProperties = {
  currentPageIndex: number;
  skipPageEvent: BindableEvent?;
  continueDialogue: () -> ();
  setCurrentPageIndex: (number) -> ();
  onPagesUpdated: (pages: {Page}) -> ();
  setIsTypingFinished: (boolean) -> ();
  dialogue: Dialogue;
}

local function MessageContainer(props: MessageContainerProperties)

  local componentIndex, setComponentIndex = React.useState(1);
  local textContainerRef = React.useRef(nil :: GuiObject?);
  local pages, testTextSegment = usePages(props.dialogue, textContainerRef, MessageTextSegment, 14);
  local currentPageIndex = props.currentPageIndex;
  local skipPageEvent = props.skipPageEvent;
  local shouldSkip, setShouldSkip = React.useState(false);

  React.useEffect(function()
  
    props.onPagesUpdated(pages);

  end, {pages :: unknown, props.onPagesUpdated});

  React.useEffect(function(): ()

    if skipPageEvent then

      local skipPageSignal = skipPageEvent.Event:Once(function()

        setShouldSkip(true);

      end);

      return function()
        
        skipPageSignal:Disconnect();

      end;

    end;

  end, {pages :: unknown, skipPageEvent});

  React.useEffect(function(): ()

    props.setIsTypingFinished(false);

  end, {pages :: any, currentPageIndex});
    
  local messageComponentList = {};

  if not testTextSegment then
    
    local page = pages[currentPageIndex];
    if page then
      
      for index, dialogueContentItem in page do

        if index > componentIndex then

          break;

        end;

        local function onComplete()

          if index == #page then
            
            setShouldSkip(false);
            props.setIsTypingFinished(true);

          elseif index == componentIndex then

            setComponentIndex(componentIndex + 1);

          end;

        end;

        local dialogueSettings = props.dialogue:getSettings();
        if typeof(dialogueContentItem) == "string" then
          
          local textSegment = React.createElement(MessageTextSegment, {
            text = dialogueContentItem;
            skipPageSignal = if skipPageEvent then skipPageEvent.Event else nil;
            layoutOrder = index;
            textSize = 14;
            key = `{currentPageIndex}.{index}`;
            letterDelay = if shouldSkip then 0 else dialogueSettings.typewriter.characterDelaySeconds;
            onComplete = onComplete;
          });

          table.insert(messageComponentList, textSegment);

        else

          local possibleComponent = dialogueContentItem:run({
            shouldSkip = shouldSkip or componentIndex > index;
            skipPageSignal = if skipPageEvent then skipPageEvent.Event else nil;
            continuePage = onComplete;
            textComponent = MessageTextSegment;
            textComponentProperties = {
              layoutOrder = index;
              letterDelay = if shouldSkip then 0 else dialogueSettings.typewriter.characterDelaySeconds;
              textSize = 14;
            };
            key = `{currentPageIndex}.{index}`;
          });

          if possibleComponent then

            table.insert(messageComponentList, possibleComponent);

          end;

        end;

      end;
 
    end;

  end;

  return React.createElement("Frame", {
    Size = UDim2.new(1, 0, 0, 117);
    BackgroundColor3 = Color3.fromHex("#202020");
    BackgroundTransparency = 0.2;
    ref = textContainerRef;
  }, {
    UIListLayout = React.createElement("UIListLayout", {
      SortOrder = Enum.SortOrder.LayoutOrder;
      FillDirection = Enum.FillDirection.Horizontal;
      Wraps = true;
    });
    UIPadding = React.createElement("UIPadding", {
      PaddingLeft = UDim.new(0, 15);
      PaddingTop = UDim.new(0, 15);
      PaddingRight = UDim.new(0, 15);
      PaddingBottom = UDim.new(0, 15);
    });
    UICorner = React.createElement("UICorner", {
      CornerRadius = UDim.new(0, 5);
    });
    MessageComponentList = React.createElement(React.Fragment, {}, testTextSegment or messageComponentList);
  });

end;

return MessageContainer;
