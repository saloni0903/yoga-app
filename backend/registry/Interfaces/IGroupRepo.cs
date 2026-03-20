
using yesmain.DTOs;
using yesmain.Models;

namespace yesmain.registry
{
    public interface IGroupRepo{
        Task CreateGroupAsync(Group group);

        Task<bool> DeleteGroupAsync(Guid Id);
        Task<GroupResponseDto> GetByIdGroupAsync(Guid Id);
        Task<List<GroupResponseDto>> GetMyGroupListAsync(Guid userId);
        Task<List<GroupMemberResponseDto>> GetGroupMemberListAsync(Guid userId);

        Task<List<GroupDto>> GetOfflineGroupsAsync(GroupFilterDto dto);
        Task<List<GroupDto>> GetOnlineGroupsAsync(GroupFilterDto dto);


        Task<bool> LeaveGroupAsync(Guid userId, Guid GroupId);

        Task<UpdateGroupResDto> UpdateGroupAsync(Guid groupId, UpdateGroupReqDto dto);

    }
}
