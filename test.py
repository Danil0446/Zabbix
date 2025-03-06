import logging
from aiogram import Bot, Dispatcher, types, Router
from aiogram.filters import Command
from aiogram.types import ChatMemberUpdated

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BOT_TOKEN = "6990547814:AAF-ezNg6wDw3kzQ87uMWOvCJrYph4DUUFo"
BANNED_WORDS = ["политика", "президент", "правительство", "оппозиция", "выборы"]

bot = Bot(token=BOT_TOKEN)
dp = Dispatcher()
router = Router()
dp.include_router(router)

@router.message(Command("start"))
async def start_command(message: types.Message):
    await message.answer("Я бот-модератор. Слежу за порядком в чате!")

@router.message()
async def check_message(message: types.Message):
    # Получаем информацию о боте правильно
    bot_info = await bot.get_me()
    
    if message.from_user.id == bot_info.id:
        return

    if message.text and any(word in message.text.lower() for word in BANNED_WORDS):
        await message.delete()
        await bot.ban_chat_member(
            chat_id=message.chat.id,
            user_id=message.from_user.id
        )
        await message.answer(
            f"Пользователь @{message.from_user.username} забанен за нарушение правил!"
        )

@router.chat_member()
async def ban_bots(event: ChatMemberUpdated):
    new_member = event.new_chat_member
    user = new_member.user
    
    if user.is_bot:
        # Проверяем статус пользователя
        if new_member.status not in ["administrator", "creator"]:
            await bot.ban_chat_member(
                chat_id=event.chat.id,
                user_id=user.id
            )
            await event.answer(
                f"Бот @{user.username} был забанен автоматически!"
            )

async def main():
    await dp.start_polling(bot)

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())